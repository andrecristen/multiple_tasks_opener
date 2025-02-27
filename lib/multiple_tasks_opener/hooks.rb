module MultipleTasksOpener
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_show_description_bottom, partial: 'issues/add_subtasks_button'
  end
end