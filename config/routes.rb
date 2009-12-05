ActionController::Routing::Routes.draw do |map|

  map.resource :session, :member => 'openid_complete'

  map.resources :users

  map.resources :tracks, :member => {:just_listened => :post}, :collection => {:wanted => :post}

  map.resources :albums, :member => {:like => :post, :hate => :post, :destroy_vote => :delete}, :has_many => [:comments]

  map.root :controller => 'home'

end
