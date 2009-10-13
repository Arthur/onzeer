class CommentsController < ApplicationController

  def new
    album.comments << Comment.new
    @comment = album.comments.last
  end

  def create
    album.comments << Comment.new(params[:comment])
    @comment = album.comments.last
    @comment.author = current_user
    @album.save
    create_or_update_response
  end

  def edit
    @comment = comment_from_params_id
  end

  def update
    @comment = comment_from_params_id
    @comment.attributes = params[:comment]
    @comment.author = current_user
    @album.save
    create_or_update_response
  end

  protected

  def create_or_update_response
    respond_to do |format|
      format.html { respond_to album }
      format.js { render :partial => 'albums/comments' }
    end
  end

  def album
    @album ||= Album.find(params[:album_id])
  end

  def comment_from_params_id
    album.comments.detect{|c| c.id == params[:id]}
  end

end
