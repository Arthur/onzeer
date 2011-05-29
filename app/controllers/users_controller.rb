class UsersController < ApplicationController
  skip_before_filter :ensure_nickname

  def index
    @users = User.all
  end

  def show
    redirect_to users_path
  end

  def edit
    user
  end

  def update
    if current_user.admin?
      user.attributes = params[:user]
    else
      user.nickname = params[:user][:nickname]
    end
    if @user.save
      redirect_to @user
    else
      render :action => "edit"
    end
  end

  protected

  def user
    @user ||= params[:id] && User.find(params[:id])
  end

  def authorized?
    current_user.admin? || user == current_user
  end

end