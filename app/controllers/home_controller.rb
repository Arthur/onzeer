class HomeController < ApplicationController
  skip_before_filter :ensure_activated

  def index
    @last_comments = UserComment.find(:all, :order => 'created_at DESC', :limit => 10)
    @last_albums = Album.find(:all, :order => 'created_at DESC', :limit => 10)
  end

end
