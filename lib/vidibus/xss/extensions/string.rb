module Vidibus
  module Xss
    module Extensions
      module String

        # Prepares XSS content for rendering.
        def escape_xss
          regexp = {
            /^\/\/.+$/ => '', # remove comments
            # /\n\s*/ => '', # trim indentation and remove linebreaks
            /\/\/\<!\[CDATA\[(.*?)\/\/\]\]\>/ => "\\1" # remove //<![CDATA[...content...//]]>
          }
          c = clone
          for s, r in regexp
            c.gsub!(s,r)
          end
          c
        end
      end
    end
  end
end