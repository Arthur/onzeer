class TracksController < ApplicationController

  def index
    respond_to do |format|
      format.html {
        conditions = {}
        conditions[:user_id] = current_user.id if params[:mine]
        @tracks = Track.paginate(params.merge(:order => 'artist, album_name, nb', :per_page => 25))
      }
      format.json { render :json => {:tracks => Track.all_since(params[:since]), :date => Time.now.utc} }
    end
  end

  def new
    @track = Track.new
  end

  def create
    @track = Track.new(params[:track])
    @track.user_id = current_user.id
    if @track.save
      redirect_to tracks_path(:mine => true)
    else
      logger.info(["could not save track: ", @track.errors, @track.content_type, @track.track_info.to_hash].inspect)
      flash[:error] = "<pre>" + ["could not save track: ", "errors: ", @track.errors.errors, "content_type:", @track.content_type, "tags:", @track.track_info.to_hash].map(&:inspect).join('<br/>') + "</pre>"
      render :new
    end
  end

  def show
    @track = Track.find(params[:id])
  end

  def edit
    @track = Track.find(params[:id])
  end

  def update
    @track = Track.find(params[:id])
    if @track.update_attributes(params[:track])
      redirect_to tracks_path
    else
      render :action => :edit
    end
  end

  def just_listened
    if TrackListening.create(:user_id => current_user.id, :track_id => params[:id])
      head :ok
    end
  end

  protected
  def authorized?
    ["index", "show", "new", "create"].include?(action_name) || current_user.admin?
  end
end
