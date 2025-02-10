Rails.application.routes.draw do
  resources :execution_tasks, only: [:new, :create]
end
