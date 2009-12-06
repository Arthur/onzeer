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
    like_or_hate_response
  end

  def hate
    album.hated_by(current_user)
    album.save
    like_or_hate_response
  end

  def destroy_vote
    album.remove_vote_of(current_user)
    album.save
    like_or_hate_response
  end

  protected
  def like_or_hate_response
    respond_to do |format|
      format.html { redirect_to album }
      format.js { render :partial => "votes"}
    end
  end

  def album
    @album ||= Album.find(params[:id])
  end

end