Redmine::Plugin.register :multiple_tasks_opener do
  name 'Multiple Tasks Opener plugin'
  author 'André Cristen'
  description 'Realiza aberturas multiplas de tarefas'
  version '0.0.5'
  url 'http://example.com/path/to/plugin'
  author_url 'https://github.com/andrecristen'

  settings default: {
    'base_activity_type' => nil,
    'related_activity_type' => nil
  }, partial: 'multiple_tasks_opener/settings'
end
