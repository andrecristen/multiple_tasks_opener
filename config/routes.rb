RedmineApp::Application.routes.draw do
  match 'settings/plugin/multiple_tasks_opener', to: 'multiple_tasks_opener#settings', via: [:get, :post]
end
