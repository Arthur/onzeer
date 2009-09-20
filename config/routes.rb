ActionController::Routing::Routes.draw do |map|

  map.resource :session, :member => 'openid_complete'

  map.resources :users

  map.resources :tracks

  map.resources :albums, :member => {:like => :post, :hate => :post}, :has_many => [:comments]

  map.root :controller => 'home'

end
