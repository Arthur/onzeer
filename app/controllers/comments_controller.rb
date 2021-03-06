class CommentsController < ApplicationController

  def new
    album.comments << Comment.new
    @comment = album.comments.last
    respond_to do |format|
      format.html { }
      format.js { render :action => 'new' }
    end
  end

  def create
    @comment = Comment.new(params[:comment])
    @comment.author = current_user
    
    if album
      album.comments << @comment
      @album.save
      @album.save_user_comment_for @comment
      create_or_update_response
    elsif post
      post.comments << @comment
      post.save
      redirect_to posts_path
    end
  end

  def edit
    @comment = comment_from_params_id
    respond_to do |format|
      format.html { }
      format.js { render :action => 'edit' }
    end
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
      format.html { redirect_to album }
      format.js { render :partial => 'albums/comments' }
    end
  end

  def comment_from_params_id
    album_or_post.comments.detect{|c| c.id.to_s == params[:id]}
  end

  def album_or_post
    album || post
  end

  def album
    @album ||= params[:album_id] && Album.find(params[:album_id])
  end

  def post
    @post ||= params[:post_id] && Post.find(params[:post_id])
  end

end
