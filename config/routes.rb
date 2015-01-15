Spree::Core::Engine.routes.draw do
  namespace :admin do 
    resources :reports, only: [] do 
      get :dmi_events, on: :collection
    end

    resources :orders, only: [] do 
      patch :retry_dmi_send, on: :member
    end
  end
end
