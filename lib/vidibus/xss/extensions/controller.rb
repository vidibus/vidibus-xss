module Vidibus
  module Xss
    module Extensions
      
      # Contains core modifications of rails controller methods.
      module Controller
        
        def self.included(base)
          base.class_eval do
            
            # Define some helper methods that should be available to helpers and views.
            helper_method :url_for, :xss_request?, :fullpath_url
          end
        end
        
        # Responds to OPTIONS request.
        # When sending data to foreign domain by AJAX, Firefox will send an OPTIONS request first.
        # 
        # == Usage:
        #
        #  Set up a catch-all route for handling 404s like this, if you haven't done it already: 
        #    match "*path" => "application#rescue_404"
        #
        #  In ApplicationController, define a method that will be called by this catch-all route:
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
          headers["Access-Control-Allow-Origin"] = "*"
          headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
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
            path = resource.attributes["src"].value
            file = url_for(path, :only_path => false)
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
            path = resource.attributes["href"].value
            file = url_for(path, :only_path => false)
            media = resource.attributes["media"].value
            resources << { :type => "text/css", :src => file, :media => media }
          end
          resources
        end

        # Renders given content string to XSS hash of resources and content.
        # If html content is given, the method tries to extract title, 
        # stylesheets and javascripts from head and content from body.
        # TODO: Allow script blocks! Add them to body?
        # TODO: Allow style blocks?
        # TODO: Check for html content
        def render_to_xss(content)
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
        
        # Main method for rendering XSS.
        # Renders given XSS resources and content to string and sets it as response_body.
        def render_xss(options = {})
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
            xss << %(vidibus.loader.load(#{resources.to_json},'#{params[:scope]}');)
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

          # wait until resources have been loaded, before rendering XSS content
          if defer
            function_name = "rx#{xss_random_string}"
            xss_content = %(var #{function_name}=function(){if(vidibus.loader.complete){#{xss_content}}else{window.setTimeout('#{function_name}()',100);}};#{function_name}();)
          end
          xss << xss_content
          
          Rails.logger.error xss

          xss_access_control_headers
          self.status = 200 # force success status
          self.response_body = xss
        end


        # Generates random string for current cycle.
        def xss_random_string
          @xss_random_string ||= begin
            random = ''
            3.times { random << rand(1000).to_s }
            random
          end
        end
        
      
        # # Invokes loading of given stylesheet.
        # def load_xss_stylesheet(url)
        #   %(vidibus.xss.loadStylesheet("#{url}");)
        # end
        # 
        # # Invokes loading of given javascript.
        # def load_xss_javascript(url)
        #   %(vidibus.xss.loadJavascript("#{url}");)
        # end
        # 
        # # Invokes embedding of html from given template.
        # def xss_template(template, options = {})
        #   scope = options.delete(:scope)
        #   html = render_to_string({ :template => template, :layout => false }).to_json
        #   %(vidibus.xss.embedHtml({scope:"#{scope}", html:#{html}});)
        # end
        # 
        # # Invokes direct redirect to given url.
        # # This works only for GET requests. See redirect_xss for more information.
        # def xss_redirect(url)
        #   %(vidibus.xss.redirect("#{url}"))
        # end
        # 
        # # Invokes setting of fragment from given url.
        # def xss_fragment(url)
        #   %(vidibus.xss.setFragment("#{url}"))
        # end
        # 
        # 
        # 
        # # Redirect to a xss url.
        # # For POST request, invoke callback action.
        # # For GET request, render redirect action directly.
        # def redirect_xss(url)
        #   if request.method == "POST" # request.post?
        #     render_xss_callback(:redirect, :to => url)
        #   else
        #     render_xss(xss_redirect(url))
        #   end
        # end  
        # 
        # # Sends data to callback handler.
        # # Inspired by:
        # #   http://paydrotalks.com/posts/45-standard-json-response-for-rails-and-jquery
        # def render_xss_callback(type, options = {})
        #   unless [ :ok, :redirect, :error ].include?(type)
        #     raise "Invalid XSS response type: #{type}"
        #   end
        # 
        #   data = {
        #     :status => type, 
        #     :html => nil, 
        #     :message => nil, 
        #     :to => nil 
        #   }.merge(options)
        # 
        #   render_xss("vidibus.xss.callbackHandler(#{data.to_json})")
        # end
        # 
        # # Sends given content parts as XSS content.
        # def render_xss(*parts)
        #   xss = parts.compact.join(";").escape_xss
        #   xss_access_control_headers
        #   send_data(xss, :type => Mime::XSS)
        # end
        # 
        # # Returns current url with full path.
        # def fullpath_url
        #   @fullpath_url ||= "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
        # end


        ### Override core extensions


        # Bypasses authenticity verification for XSS requests.
        # TODO: Verify authenticity in other ways (Single Sign-on).
        def verify_authenticity_token
          xss_request? || super
        end
        
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
        # Renders XSS response, if requested
        def render(*args, &block)
          args << options = args.extract_options!
          if xss_request? or options[:format] == :xss

            # embed xss.get
            if path = options[:path]
              content = render_to_string(:template => "layouts/#{get_layout(:xss)}")
              xss = render_to_xss(content)
              xss[:get] = "/#{path}"
              xss.delete(:content) # make sure not content will be embedded

            # embed xss content
            else
              content = render_to_string(*args, &block)
              xss = render_to_xss(content)
            end

            render_xss(xss)
          else
            super(*args, &block)
          end
        end
      end
    end
  end
end
