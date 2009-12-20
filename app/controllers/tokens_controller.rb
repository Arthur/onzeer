class TokensController < ApplicationController
  skip_before_filter :login_required, :only => :create
  skip_before_filter :verify_authenticity_token

  def create
    new_token = Digest::SHA1.hexdigest("#{Time.now}-#{rand(10000)}")
    Rails.cache.write(new_token, "new")
    render :text => new_token
  end

  def show
    token = params[:id]
    value = Rails.cache.fetch(token)
    if value == "new" || value == current_user.id
      Rails.cache.write(token, current_user.id) if value == "new"
      render :text => "ok"
    else
      render :head => :unauthorized
    end
  end

end
