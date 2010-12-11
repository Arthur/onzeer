class HomeController < ApplicationController
  skip_before_filter :ensure_activated

  def index
    @last_blog_post = Post.last
    @last_listenings = TrackListening.find(:all, :order => 'created_at DESC', :limit => 10)
    @last_comments = UserComment.find(:all, :order => 'created_at DESC', :limit => 10)
    @last_albums = Album.find_last
    @users = User.all.sort_by{|u| u.last_uploaded_albums.empty? ? 0 : u.last_uploaded_albums.total_entries}.reverse
  end

end
