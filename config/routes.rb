RedmineApp::Application.routes.draw do
  post 'multiple_tasks_opener/save_settings', to: 'multiple_tasks_opener#save_settings', as: 'save_settings'
end
