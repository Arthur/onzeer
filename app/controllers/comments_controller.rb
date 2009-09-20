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
    redirect_to @album
  end

  def edit
    @comment = comment_from_params_id
  end

  def update
    @comment = comment_from_params_id
    @comment.attributes = params[:comment]
    @comment.author = current_user
    @album.save
    redirect_to @album
  end

  protected
  def album
    @album ||= Album.find(params[:album_id])
  end

  def comment_from_params_id
    album.comments.detect{|c| c.id == params[:id]}
  end

end
