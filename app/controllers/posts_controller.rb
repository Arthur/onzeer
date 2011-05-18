class PostsController < ApplicationController

  def index
    @posts = Post.all
    @comment = Comment.new
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(params[:post])
    @post.author_id = current_user.id
    if @post.save
      redirect_to :action => :index
    else
      render :action => :new
    end
  end

  def edit
    @post = Post.find(params[:id])
    render :action => :new
  end

  def update
    @post = Post.find(params[:id])
    @post.author_id = current_user.id
    if @post.update_attributes(params[:post])
      redirect_to :action => :index
    else
      render :action => :edit
    end
  end

end
