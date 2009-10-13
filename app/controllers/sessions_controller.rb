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
    logger.debug ["openid_url_or_gmail", session.openid_url_or_gmail].inspect
    open_id_request = consumer.begin(session.openid_url_or_gmail)

    if session.gmail?
      ax_request = OpenID::AX::FetchRequest.new
      ax_request.add(OpenID::AX::AttrInfo.new("http://schema.openid.net/contact/email", nil, true ))
      open_id_request.add_extension(ax_request)
    else
      sregreq = OpenID::SReg::Request.new
      sregreq.request_fields(['email','nickname'], true)
      open_id_request.add_extension(sregreq)
      open_id_request.return_to_args['did_sreg'] = 'y'      
    end
    redirect_to open_id_request.redirect_url(root_url, openid_complete_session_url, params[:immediate])
  end

  def destroy
    self.current_user = nil
    redirect_to new_session_path
  end

  def openid_complete
    parameters = params.reject{|k,v|request.path_parameters[k]}
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
        email = ax_response.data["http://schema.openid.net/contact/email"].first
        flash[:ax_response] = ax_response.data
      end
      sreg_resp = OpenID::SReg::Response.from_success_response(openid_response)
      unless sreg_resp.empty?
        email = sreg_resp.data["email"]
      end
      flash[:sreg_results] = sreg_resp.data
    when OpenID::Consumer::SETUP_NEEDED
      flash[:alert] = "Immediate request failed - Setup Needed"
    when OpenID::Consumer::CANCEL
      flash[:alert] = "OpenID transaction cancelled."
    else
      flash[:alert] = "Unknow OpenID status #{openid_response.status}"
    end
    if email
      self.current_user = User.find_or_create_by_email(email)
      redirect_to root_path
    else
      redirect_to new_session_path
    end
  end

  protected

  def consumer
    @consumer ||= OpenID::Consumer.new(session, OpenIdStore.new)
  end

end