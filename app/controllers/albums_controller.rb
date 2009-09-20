class AlbumsController < ApplicationController

  def index
    @albums = Album.all
  end

  def show
    album
  end

  def edit
    album
  end

  def update
    if album.update_attributes(params[:album])
      redirect_to album
    else
      render :action => :edit
    end
  end

  def like
    album.loved_by(current_user)
    album.save
    redirect_to album
  end

  def hate
    album.hated_by(current_user)
    logger.debug album.save
    logger.debug [album, album.votes].inspect
    redirect_to album
  end

  protected
  def album
    @album ||= Album.find(params[:id])
  end

end