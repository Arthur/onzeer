class AlbumsController < ApplicationController

  def index
    conditions = {}
    if q = params[:q]
     conditions = { '$or' => [ {"name" => /#{q}/i}, {'artist' => /#{q}/i} ] }
    end
    if params[:randomly]
      @albums = Album.find_randomly
      render :partial => "albums/randomly"
      return
    end
    if params[:last]
      albums_params = {:last => true}
      if params[:user_id]
        user = User.find(params[:user_id])
        albums_params[:user_id] = user.id
        albums = user.last_uploaded_albums(params[:page])
      else
        albums = Album.find_last(params[:page])
      end
      render :partial => "albums/paginated", :locals => {:albums => albums, :albums_params => albums_params}
      return
    end
    if params[:user_id] && params[:preferred]
      user = User.find(params[:user_id])
      votes = user.last_votes(params[:page])
      render :partial => "albums/paginated", :locals => {
        :albums => votes.map(&:album),
        :paginator => votes,
        :albums_params => {:user_id => user.id, :preferred => true}
      }
      return
    end
    if params[:user_id] && params[:list_id]
      user = User.find(params[:user_id])
      list = user.list_by_id(params[:list_id])
      paginator = Paginator.new(list.album_ids, :class => Album, :page => params[:page])
      render :partial => "albums/paginated", :locals => {
        :albums => paginator.objects_in_page,
        :paginator => paginator,
        :albums_params => {:user_id => list.user.id, :list_id => list.list_id}
      }
      return
    end

    @albums ||= Album.paginate(:order => 'artist, name', :per_page => params[:limit] || 50, :conditions => conditions, :page => params[:page])
  end

  def show
    album
    respond_to do |format|
      format.html {}
      format.json do
        render :json => MongoEmbeddedRecord.json_encoder({ :view => render_to_string(:action => "show.html", :layout => false), :tracks => album.tracks.map{|r| r.attributes} }).to_json
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
