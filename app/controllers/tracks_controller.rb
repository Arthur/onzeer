class TracksController < ApplicationController

  def index
    respond_to do |format|
      format.html { 
        @tracks = Track.paginate(params.merge(:order => 'artist, album_name, nb', :per_page => 25))
      }
      format.json { render :json => {:tracks => Track.all_since(params[:since]), :date => Time.now.utc} }
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

  protected
  def authorized?
    ["index", "show"].include?(action_name) || current_user.admin?
  end
end
