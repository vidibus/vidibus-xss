module Vidibus
  module Xss
    module Extensions
      module View

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
