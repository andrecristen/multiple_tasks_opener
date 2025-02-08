require_relative 'lib/multiple_tasks_opener/hooks'

Redmine::Plugin.register :multiple_tasks_opener do
  name 'Multiple Tasks Opener'
  author 'André Cristen'
  description 'Plugin para abrir múltiplas tarefas no Redmine'
  version '0.0.1'
  url 'https://github.com/andrecristen/multiple_tasks_opener'
  author_url 'https://github.com/andrecristen'
  settings default: { 'open_issues' => [{ 'tracker_origin' => '', 'related_trackers' => [] }] }, partial: 'settings/multiple_tasks_opener_settings'
  require_relative 'lib/multiple_tasks_opener/hooks'
end
