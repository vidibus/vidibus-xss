# # Renders templates as XSS-Includes.
# #
# # == Usage:
# #
# #   respond_to do |format|
# #     format.html
# #     format.xss { render :xss => "forms/index.haml", :scope => "form", :stylesheet => "form.css" }
# #   end
# #
# ActionController::Renderers.add :xss do |template, options|
#   html = xss_template(template, :scope => options[:scope])
#   if file = options[:stylesheet]
#     stylesheet = xss_stylesheet(file)
#   end
#   fragment = xss_fragment(fullpath_url) # Set current url fragment
#   render_xss(stylesheet, html, fragment)
# end