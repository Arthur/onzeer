# see :
# http://www.w3.org/TR/XMLHttpRequest2/
# http://webreflection.blogspot.com/2009/03/safari-4-multiple-upload-with-progress.html

require 'rack/request'

module Rack
  class Request
    def post_with_safari_xhr2_upload
      if (name = @env["HTTP_X_INPUT_NAME"]) && (filename = @env["HTTP_X_FILE_NAME"])
        # p ["post_with_safari_xhr2_upload", name, filename, @env["rack.input"]]
        form_vars = @env["rack.input"].read
        @env["rack.request.form_vars"] = form_vars

        input = @env['rack.input']
        input.rewind

        body = Tempfile.new("RackCustomInputFromSafari")
        body.binmode  if body.respond_to?(:binmode)
        body << input.read
        body.rewind

        data = {:filename => filename, :name => name, :tempfile => body}
        params = {}
        Utils.normalize_params(params, name, data)

        @env["rack.request.form_hash"] = params
      else
        post_without_safari_xhr2_upload
      end
    end
    alias_method :post_without_safari_xhr2_upload, :POST
    alias_method :POST, :post_with_safari_xhr2_upload
  end
end
