Dradis::Plugins::Projects::Engine.routes.draw do
  resource :package,  only: [:show]
  resource :template, only: [:show]
end
