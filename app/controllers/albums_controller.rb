class AlbumsController < ApplicationController

  def index
    conditions = {}
    if q = params[:q]
      # conditions = {:artist => /#{q}/i, :name => /#{q}/i}
      # see http://www.mongodb.org/display/DOCS/OR+operations+in+query+expressions
      conditions = { "$where" => "this.name.match(/#{q}/i) || this.artist.match(/#{q}/i)" }
    end
    if params[:randomly]
      @albums = Album.find_randomly
      render :partial => "albums/randomly"
      return
    end
    if params[:last_page]
      @last_albums = Album.find_last(params[:last_page])
      render :partial => "albums/last"
      return
    end
    if params[:user_id] && params[:preferred]
      user = User.find(params[:user_id])
      votes = user.last_votes(params[:page])
      render :partial => "albums/preferred", :locals => {:albums => votes.map(&:album), :page => votes.current_page, :user => user}
    end
    @albums ||= Album.paginate(:order => 'artist, name', :per_page => params[:limit] || 50, :conditions => conditions, :page => params[:page])
  end

  def show
    album
    respond_to do |format|
      format.html {}
      format.json do
        render :json => { :view => render_to_string(:action => "show.html", :layout => false), :tracks => album.tracks }
      end
    end
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

  def mb_releases
    @releases = MusicBrainzRelease.find_all_by_title_and_artist(album.name, album.artist)
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