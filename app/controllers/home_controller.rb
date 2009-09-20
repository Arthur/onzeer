class HomeController < ApplicationController
  skip_before_filter :ensure_activated
end