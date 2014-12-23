Spree::Core::Engine.routes.draw do
  namespace :admin do 
    resources :reports, only: [] do 
      get :dmi_events, on: :collection
    end
  end
end
