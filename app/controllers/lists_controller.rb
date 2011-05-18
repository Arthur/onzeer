class ListsController < ApplicationController

  def index
    user = params[:user_id] ? User.find(params[:user_id]) : current_user
    @lists = user.user_lists.each{|l| l.user = user}
    @new_list = List.new
  end

  def create
    list = List.new(params[:list])
    list.author = current_user
    list.save
    redirect_to :action => :index
  end

  def add_album
    list.add(:album_id => params[:album_id], :author => current_user)
    list_in_album_update_response
  end

  def remove_album
    list.remove(:album_id => params[:album_id], :author => current_user)
    list_in_album_update_response
  end

  def accept_modification
    logger
    modification && modification.accept(:author => current_user)
    redirect_to :action => :index
  end

  def reject_modification
    modification && modification.reject(:author => current_user)
    redirect_to :action => :index
  end

  def follow
    list.follow_by(current_user)
    redirect_to :action => :index
  end

protected

  def list_in_album_update_response
    respond_to do |format|
      format.js do
        @album = Album.find(params[:album_id])
        render :partial => "albums/lists"
      end
      format.html do
        redirect_to album_path(params[:album_id])
      end
    end
  end

  def list
    @list ||= List.find(params[:id])
  end

  def modification
    @modification ||= list.modifications.detect{|m| m.id.to_s == params[:modification_id]}
    @modification.list = list
    @modification
  end

end
