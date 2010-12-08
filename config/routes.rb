ActionController::Routing::Routes.draw do |map|

  map.resource :session, :member => {:openid_complete => :get}

  map.resources :tokens

  map.resources :users, :has_many => :lists

  map.resources :tracks, :member => {:just_listened => :post}, :collection => {:wanted => :post}

  map.resources :albums, :member => {:like => :post, :hate => :post, :destroy_vote => :delete, :mb_releases => :get}, :has_many => [:comments]

  map.resources :posts, :has_many => [:comments]
  map.connect 'blog', :controller => "posts"

  map.resources :lists, :member => {
    :follow => :post,
    :add_album => :post, 
    :remove_album => :delete,
    :accept_modification => :post,
    :reject_modification => :delete,
  }

  map.root :controller => 'home'

end
