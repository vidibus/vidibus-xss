module Vidibus
  module Xss
    module Extensions
      
      # Contains core modifications of rails helper methods.
      module View
    
        # # Renders links as remote ones for XSS requests.
        # def link_to(*args, &block)
        #   if xss_request?
        #     options = args.extract_options!
        #     set_xss_html_attributes(options)
        #     args << options
        #   end
        #   super
        # end
        #   
        # # def form_for(record_or_name_or_array, *args, &proc)
        # def form_tag(url_for_options = {}, options = {}, *parameters_for_url, &block)
        #   if xss_request?
        #     set_xss_html_attributes(options)
        #   end
        #   super
        # end
  
        # Sets XSS attributes on given ones.
        def set_xss_html_attributes(attributes)
          attributes['data-xss'] = true
          attributes.delete(:remote) # avoid concurrent remote calls
          attributes
        end
      end
    end
  end
end
