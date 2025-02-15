class ExecutionTasksController < IssuesController
  before_action :find_issue, only: [:new, :create]
  before_action :set_project
  before_action :set_priorities
  before_action :set_versions

  helper :issues
  include IssuesHelper

  def new
    @config = load_config(@issue.tracker_id)
  end

  def create
    related_tasks = params[:related_tasks]
    if related_tasks.present? && related_tasks.is_a?(Array)
      related_tasks.each do |task|
        new_task = Issue.new(
          project_id: @issue.project_id,
          tracker_id: task['type'],
          subject: task['subject'] || @issue.subject,
          description: task['description'],
          assigned_to_id: task['assigned_to_id'] || @issue.assigned_to_id,
          estimated_hours: task['estimated_hours'] || @issue.estimated_hours,
          start_date: @issue.start_date,
          due_date: @issue.due_date,
          priority_id: @issue.priority_id,
          status_id: @issue.status_id,
          author_id: User.current.id,
          parent_id: @issue.id
        )

        # Tentativa para campos personalizados @todo revisar isso
        # @issue.custom_fields.each do |cf|
        #   if cf.trackers.include?(Tracker.find_by(id: new_task.tracker_id))
        #     new_task.custom_field_values[cf.id.to_s] = @issue.custom_field_values[cf.id.to_s]
        #   end
        # end

        unless new_task.save
          flash[:error] = "Erro ao criar as tarefas. Erros: #{new_task.errors.full_messages.join('<br/> -')}"
          redirect_to @issue and return
        end
      end
      flash[:notice] = 'Tarefas de Execução geradas com sucesso!'
      redirect_to @issue
    else
      flash[:error] = 'Formato inválido para tarefas relacionadas'
      redirect_to @issue
    end
  end

  private

  def find_issue
    @issue = Issue.find_by(id: params[:open_from])
    raise ActiveRecord::RecordNotFound, "Atividade não encontrada" if @issue.nil?
    @parent_issue_author = @issue.author&.name
    @parent_issue_assigned_to = @issue.assigned_to&.name
  end

  def set_project
    @project = @issue.project
  end

  def set_priorities
    @priorities = IssuePriority.active
  end

  def set_versions
    @versions = @issue.assignable_versions
  end

  def load_config(tracker_origin)
    config = Setting.plugin_multiple_tasks_opener['open_issues']
    return [] unless config.is_a?(Hash)
    config.each_value do |entry|
      return entry['related_trackers'].values if entry['tracker_origin'].to_s == tracker_origin.to_s
    end
    []
  end
end