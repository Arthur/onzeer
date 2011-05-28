Onzeer::Application.routes.draw do

  resource :session do
    member do 
      get :openid_complete
    end
  end

  resources :tokens

  resources :users do
    resources :lists
  end

  resources :tracks do
    member do
      post :just_listened
    end
    collection { post :wanted}
  end

  resources :albums do
    member do
      post :like
      post :hate
      delete :destroy_vote
      get :mb_releases
    end
    resources :comments
  end

  resources :posts do
    resources :comments
  end

  # match 'blog' :to => "posts"

  resources :lists do
    member do
      post :follow
      post :add_album
      delete :remove_album
      post :accept_modification
      delete :reject_modification
    end
  end

  root :to => 'home#index'

end
