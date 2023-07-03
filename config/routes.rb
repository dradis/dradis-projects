Dradis::Plugins::Projects::Engine.routes.draw do
  resources :projects, only: [] do
    resource :package,  only: [:create]
    resource :template, only: [:create]
  end
end
