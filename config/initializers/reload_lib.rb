# http://stackoverflow.com/questions/3282655/ruby-on-rails-3-reload-lib-directory-for-each-request
if Rails.env == "development"
  lib_reloader = ActiveSupport::FileUpdateChecker.new(Dir["lib/**/*"], true) do
    Rails.application.reload_routes! # or do something better here
  end

  ActionDispatch::Callbacks.to_prepare do
    lib_reloader.execute_if_updated
  end
end
