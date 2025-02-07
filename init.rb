Redmine::Plugin.register :multiple_tasks_opener do
  name 'Multiple Tasks Opener plugin'
  author 'André Cristen'
  description 'Realiza aberturas multiplas de tarefas'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'https://github.com/andrecristen'
  settings default: {}, partial: 'multiple_tasks_opener/settings'
  project_module :multiple_tasks_opener do
    permission :manage_multiple_tasks_opener, { multiple_tasks_opener: [:settings, :save_settings] }, public: true
  end
end
