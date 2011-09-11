class TracksController < ApplicationController
  skip_before_filter [:verify_authenticity_token], :only => [:create, :wanted]

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
    puts "DEBUG"
    @track = Track.new
  end

  def create
    puts "DEBUG"
    raise "debug"
    @track = Track.new(params[:track])
    @track.user_id = current_user.id if current_user
    logger.info("hello there")
    if @track.save
      if params[:qt_uploader]
        render :text => "Ok thanks."
      else
        redirect_to tracks_path(:mine => true)
      end
    else
      logger.info(["could not save track: ", @track.errors, @track.content_type, @track.track_info.to_hash].inspect)
      if params[:qt_uploader]
        render :text => "Sorry : #{@track.errors.errors.inspect}"
      else
        flash[:error] = "<pre>" + ["could not save track: ", "errors: ", @track.errors.errors, "content_type:", @track.content_type, "tags:", @track.track_info.to_hash].map(&:inspect).join('<br/>') + "</pre>"
        render :new
      end
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

  def wanted
    response = Track.want(params[:track])
    logger.info("response: #{response}")
    render :text => response
  end

  protected
  def authorized?
    ["index", "show", "new", "create", "just_listened", "wanted"].include?(action_name) || current_user.admin?
  end
end
