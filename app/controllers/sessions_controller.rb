require 'openid/store/memcache'
require 'openid/extensions/ax'
require 'openid/extensions/sreg'

class SessionsController < ApplicationController
  skip_before_filter :login_required

  def new
    @session = Session.new
  end

  def create
    session = Session.new(params[:session])
    logger.debug ["openid_provider_url", session.openid_provider_url].inspect
    open_id_request = consumer.begin(session.openid_provider_url)

    ax_request = OpenID::AX::FetchRequest.new
    ax_request.add(OpenID::AX::AttrInfo.new("http://axschema.org/contact/email", nil, true ))
    open_id_request.add_extension(ax_request)

    redirect_to open_id_request.redirect_url(root_url, openid_complete_session_url, params[:immediate])
  end

  def destroy
    self.current_user = nil
    redirect_to new_session_path
  end

  def openid_complete
    parameters = params.reject{|k,v| !(k =~ /^openid/) }
    openid_response = consumer.complete(parameters, openid_complete_session_url)
    email = nil
    case openid_response.status
    when OpenID::Consumer::FAILURE
      if openid_response.display_identifier
        flash[:error] = "Verification of #{openid_response.display_identifier} failed: #{openid_response.message}"
      else
        flash[:error] = "Verification failed: #{openid_response.message}"
      end
    when OpenID::Consumer::SUCCESS
      ax_response = OpenID::AX::FetchResponse.from_success_response(openid_response)
      if ax_response && ax_response.data
        email = ax_response.data["http://axschema.org/contact/email"].first
        flash[:ax_response] = ax_response.data
      end
    when OpenID::Consumer::SETUP_NEEDED
      flash[:error] = "Immediate request failed - Setup Needed"
    when OpenID::Consumer::CANCEL
      flash[:error] = "OpenID transaction cancelled."
    else
      flash[:error] = "Unknow OpenID status #{openid_response.status}"
    end
    if email
      # self.current_user = User.find_or_create_by_email(email)
      session[:email] = email
      redirect_to session[:return_to] || root_path
    else
      redirect_to new_session_path
    end
  end

  protected

  def consumer
    @consumer ||= OpenID::Consumer.new(session, OpenIdStore.new)
  end

end
