# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  before_filter :login_required
  before_filter :ensure_activated
  before_filter :ensure_nickname

  protected
  def authorized?
    true
  end

  def login_required
    unless current_user && authorized?
      respond_to do |f|
        f.html do
          if current_user
            redirect_to root_path
          else
            session[:return_to] = request.url
            redirect_to new_session_path
          end
        end
        f.all { head :unauthorized }
      end
    end
  end

  def ensure_activated
    if current_user && !current_user.activated
      render :file => "sessions/waiting_activation"
      false
    end
  end

  def ensure_nickname
    if current_user && current_user.nickname.blank?
      respond_to do |f|
        f.html { redirect_to edit_user_path(current_user)}
      end
    end
  end

  def current_user
    return User.all.first if Rails.env == "development"
    return @current_user unless @current_user.nil?
    @current_user ||= session[:user_id] && User.find(session[:user_id]) rescue nil
    @current_user ||= params[:token] && User.find(Rails.cache.fetch(params[:token])) rescue nil
    @current_user ||= false
  end
  helper_method :current_user

  def current_user=(user)
    @current_user = user
    session[:user_id] = user && user.id
  end

end
