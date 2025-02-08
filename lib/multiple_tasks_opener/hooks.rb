module MultipleTasksOpener
  class Hooks < Redmine::Hook::ViewListener
    # Adiciona o botão "Adicionar Sub Tarefas" na tela da issue
    render_on :view_issues_show_details_bottom, partial: 'issues/add_subtasks_button'
  end
end