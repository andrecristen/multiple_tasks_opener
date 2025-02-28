Redmine::Plugin.register :multiple_tasks_opener do
  name 'Multiple Tasks Opener'
  author 'André Cristen'
  description 'Plugin para abrir múltiplas tarefas no Redmine'
  version '0.0.1'
  url 'https://github.com/andrecristen/multiple_tasks_opener'
  author_url 'https://github.com/andrecristen'
  settings default: { 'open_issues' => { '0' => { 'tracker_origin' => '', 'related_trackers' => {} } } }, partial: 'settings/multiple_tasks_opener_settings'
  project_module :multiple_tasks_opener do
    permission :manage_execution_tasks, { execution_tasks: [:new, :create] }, require: :loggedin
  end
  require_relative 'lib/multiple_tasks_opener/hooks'
end
