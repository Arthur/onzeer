class AlbumsController < ApplicationController

  def index
    conditions = {}
    if q = params[:q]
      # conditions = {:artist => /#{q}/i, :name => /#{q}/i}
      # see http://www.mongodb.org/display/DOCS/OR+operations+in+query+expressions
      conditions = { "$where" => "this.name.match(/#{q}/i) || this.artist.match(/#{q}/i)" }
    end
    @albums = Album.paginate(:order => 'artist, name', :per_page => 50, :conditions => conditions, :page => params[:page])
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
    UserVote.create(:album_id => album.id, :author_id => current_user.id, :note => 1)
    redirect_to album
  end

  def hate
    album.hated_by(current_user)
    UserVote.create(:album_id => album.id, :author_id => current_user.id, :note => -1)
    logger.debug album.save
    logger.debug [album, album.votes].inspect
    redirect_to album
  end

  protected
  def album
    @album ||= Album.find(params[:id])
  end

end