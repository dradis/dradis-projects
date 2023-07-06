Dradis::Plugins::Projects::Engine.routes.draw do
  resources :projects, only: [] do
    resource :package,  only: [:create], path: '/export/package'
    resource :template, only: [:create], path: '/export/template'
  end
end
