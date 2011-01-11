require "nokogiri"

module Vidibus
  module Xss
    module Extensions
      module Controller

        extend ActiveSupport::Concern

        included do
          helper_method :url_for, :xss_request?, :fullpath_url, :render_xss_string, :extract_xss
          respond_to :html, :xss
          rescue_from ActionController::RoutingError, :with => :rescue_404
        end

        # Set hostname of clients that are allowed to access this resource.
        def xss_clients
          @xss_clients ||= [request.headers["Origin"]]
        end

        protected

        # Returns true if requesting client is in list of xss clients.
        def xss_client?
          @is_xss_client ||= !!xss_client
        end

        # Returns requesting client if it is in list of xss clients.
        def xss_client
          @xss_client ||= begin
            return unless origin = request.headers["Origin"]
            clients = xss_clients
            unless xss_clients
              raise %(Define a list of xss_clients in your ApplicationController that returns all hosts that are allowed to access your service.\nExample: %w[http://myconsumer.local])
            end
            if clients.is_a?(Array)
              clients.detect { |c| c == origin }
            elsif clients == origin
              origin
            end
          end
        end

        # Returns layout for current request format.
        def get_layout(format = nil)
          (xss_request? or format == :xss) ? 'xss.haml' : 'application'
        end

        # IMPORTANT: restart server to apply modifications.
        def rescue_404
          return if respond_to_options_request
          super
        end

        # Responds to OPTIONS request.
        # When sending data to foreign domain by AJAX, Firefox will send an OPTIONS request first.
        #
        # == Usage:
        #
        #  Set up a catch-all route for handling 404s like this, if you haven't done it already:
        #
        #    match "*path" => "application#rescue_404"
        #
        #  In ApplicationController, define a method that will be called by this catch-all route:
        #
        #    def rescue_404
        #      respond_to_options_request
        #    end
        #
        def respond_to_options_request
          return unless options_request?
          xss_access_control_headers
          render(:text => "OK", :status => 200) and return true
        end

        # Returns true if current request is in XSS format.
        def xss_request?
          @is_xss ||= begin
            if request.format == :xss
              true
            elsif request.format == "*/*"
              if env["REQUEST_URI"].match(/[^\?]+\.xss/) # try to detect format by file extension
                true
              end
            end
          end
        end

        # Returns true if the current request is an OPTIONS request.
        def options_request?
          @is_options_request ||= request.method == "OPTIONS"
        end

        # Set access control headers to allow cross-domain XMLHttpRequest calls.
        # For more information, see: https://developer.mozilla.org/En/HTTP_access_control
        def xss_access_control_headers
          headers["Access-Control-Allow-Origin"] = xss_client if xss_client
          headers["Access-Control-Allow-Methods"] = "GET,PUT,POST,DELETE,HEAD,OPTIONS"
          headers["Access-Control-Allow-Headers"] = "Content-Type,Depth,User-Agent,X-File-Size,X-Requested-With,If-Modified-Since,X-File-Name,Cache-Control"
          headers["Access-Control-Allow-Credentials"] = "true"
          headers["Access-Control-Max-Age"] = "1728000" # Cache this response for 20 days.
        end

        def extract_xss_html(dom)
          dom.css('body').first.inner_html
        end

        # Extracts javascript resources from given DOM object.
        #
        # Usage:
        #
        #   dom = Nokogiri::HTML(<html></html>)
        #   urls = extract_xss_javascripts(dom)
        #
        def extract_xss_javascripts(dom)
          resources = []
          for resource in dom.css('head script[type="text/javascript"]')
            next unless src = resource.attributes["src"]
            file = url_for(src.value, :only_path => false)
            resources << { :type => "text/javascript", :src => file }
          end
          resources
        end

        # Extracts stylesheet resources from given DOM object.
        #
        # Usage:
        #
        #   dom = Nokogiri::HTML(<html></html>)
        #   urls = extract_xss_stylesheets(dom)
        #
        def extract_xss_stylesheets(dom)
          resources = []
          for resource in dom.css('head link[type="text/css"]')
            next unless href = resource.attributes["href"]
            file = url_for(href.value, :only_path => false)
            media = resource.attributes["media"].value
            resources << { :type => "text/css", :src => file, :media => media }
          end
          resources
        end

        # Extracts XSS hash of resources and content from given content string.
        # If html content is given, the method tries to extract title,
        # stylesheets and javascripts from head and content from body.
        # TODO: Allow script blocks! Add them to body?
        # TODO: Allow style blocks?
        # TODO: Check for html content
        def extract_xss(content)
          dom = Nokogiri::HTML(content)
          {
            :resources => extract_xss_javascripts(dom) + extract_xss_stylesheets(dom),
            :content => extract_xss_html(dom)
          }
        end

        # Redirect to a xss url.
        # For POST request, invoke callback action.
        # For GET request, render redirect action directly.
        def redirect_xss(url)
          if request.method == "POST" # request.post? does not work??
            render_xss_callback(:redirect, :to => url)
          else
            render_xss(:redirect => url)
          end
        end

        # Sends data to callback handler.
        # Inspired by:
        #   http://paydrotalks.com/posts/45-standard-json-response-for-rails-and-jquery
        def render_xss_callback(type, options = {})
          unless [ :ok, :redirect, :error ].include?(type)
            raise "Invalid XSS response type: #{type}"
          end

          data = {
            :status => type,
            :html => nil,
            :message => nil,
            :to => nil
          }.merge(options)

          render_xss(:callback => data)
        end

        # Controller method for rendering xss content.
        def render_xss(options = {})
          xss = render_xss_string(options)
          xss_access_control_headers
          self.content_type = Mime::XSS
          self.status = 200 # force success status
          self.response_body = xss
        end

        # Main method for rendering XSS.
        # Renders given XSS resources and content to string and sets it as response_body.
        def render_xss_string(options = {})
          resources = options.delete(:resources)
          content = options.delete(:content)
          path = options.delete(:get)
          redirect = options.delete(:redirect)
          callback = options.delete(:callback)

          raise "Please provide :content, :get, :redirect or :callback." unless content or path or redirect or callback
          raise "Please provide either :content to render or :get location to load. Not both." if content and path

          xss = ""

          # determine scope
          if !(scope = params[:scope]).blank?
            scope = "$('##{scope}')"
          else
            scope = "$s#{xss_random_string}"
            xss << %(var #{scope}=vidibus.xss.detectScope();)
          end

          # set host for current scope
          xss << %(vidibus.xss.setHost('#{request.protocol}#{request.host_with_port}',#{scope});)

          # render load invocations of XSS resources
          if resources and resources.any?
            xss << %(xssLoader.load(#{resources.to_json},'#{params[:scope]}');)
            defer = true
          end

          # render XSS content
          xss_content = begin
            if !content.blank?
              %(vidibus.xss.embed(#{content.escape_xss.to_json},#{scope});)
            elsif path
              %(vidibus.xss.get('#{path}',#{scope});)
            elsif redirect
              %(vidibus.xss.redirect('#{redirect}',#{scope});)
            elsif callback
              %(vidibus.xss.callback(#{callback.to_json},#{scope});)
            end
          end

          xss_content << xss_csrf_vars

          # wait until resources have been loaded, before rendering XSS content
          if defer
            function_name = "rx#{xss_random_string}"
            xss_content = %(var #{function_name}=function(){if(xssLoader.complete){#{xss_content}}else{window.setTimeout('#{function_name}()',100);}};#{function_name}();)
          end
          xss << xss_content
        end

        # Generates random string for current cycle.
        def xss_random_string
          @xss_random_string ||= begin
            random = ''
            3.times { random << rand(1000).to_s }
            random
          end
        end

        # Sets vars for CSRF protection.
        def xss_csrf_vars
          %(vidibus.csrf.param='#{request_forgery_protection_token}', vidibus.csrf.token='#{form_authenticity_token}';)
        end

        ### Override core extensions

        # # Bypasses authenticity verification for XSS requests.
        # # TODO: Verify authenticity in other ways (Single Sign-on).
        # def verify_authenticity_token
        #   xss_request? || super
        # end

        # Extension of url_for:
        # Transform given relative paths into absolute urls.
        #
        # Usage:
        #   url_for("/stylesheets/vidibus.css", :only_path => false)
        #
        def url_for(*args)
          options, special = args
          if options.is_a?(String) and special and special[:only_path] == false
            unless options =~ /\Ahttp/
              options = "#{request.protocol}#{request.host_with_port}#{options}"
            end
          end
          super(options)
        end

        # Chatches redirect calls for XSS locations.
        # If a XSS location is given, XSS content will be rendered instead of redirecting.
        #
        # == Usage:
        #
        #   respond_to do |format|
        #     format.xss  { redirect_to forms_path }
        #   end
        #
        def redirect_to(*args)
          if xss_request?
            redirect_xss(args.first)
          else
            super
          end
        end

        # Extensions of render method:
        # Renders XSS response if requested.
        # If Origin is withing allowed xss_clients, xss heades will be sent to allow authorization.
        def render(*args, &block)
          args << options = args.extract_options!
          if xss_request? or options[:format] == :xss

            # embed xss.get
            if path = options[:path]
              template = options[:template]
              if template === false
                xss = {}
              else
                template ||= "layouts/#{get_layout(:xss)}"
                content = render_to_string(:template => template)
                xss = extract_xss(content)
              end
              xss[:get] = "/#{path}"
              xss.delete(:content) # Ensure that not content will be embedded!

            # embed xss content
            else
              content = render_to_string(*args, &block)
              xss = extract_xss(content)
            end

            render_xss(xss)
          else
            if xss_client?
              xss_access_control_headers
            end
            super(*args, &block)
          end
        end
      end
    end
  end
end
