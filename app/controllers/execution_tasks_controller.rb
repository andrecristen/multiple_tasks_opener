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
        new_task = create_issue(task)
        if new_task.save
          create_attachments_issue(new_task, task)
        else
          flash[:error] ||= "Erro ao criar tarefa: <ul>"
          flash[:error] += new_task.errors.full_messages.map { |message| "<li>#{message}</li>" }.join
          flash[:error] += "</ul>"
          @related_tasks = related_tasks
          render :new and return
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

  def create_issue(task)
    Issue.new(
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
  end

  def create_attachments_issue(new_task, task)
    if task['attachments'].present?
      task['attachments'].each do |_index, attachment_params|
        file = Attachment.create(
          container: new_task,
          file: uploaded_file_from_params(attachment_params),
          author: User.current,
          description: attachment_params['description']
        )

        unless file.persisted?
          flash[:error] ||= "Erro ao anexar arquivos: <ul>"
          flash[:error] += "<li>#{file.errors.full_messages.join(', ')}</li>"
          flash[:error] += "</ul>"
        end
      end
    end
  end

  def uploaded_file_from_params(attachment_params)
    return nil unless attachment_params['token']

    attachment = Attachment.find_by_token(attachment_params['token'])
    return nil unless attachment&.diskfile

    temp_file = Tempfile.new(File.basename(attachment.diskfile))
    FileUtils.copy_file(attachment.diskfile, temp_file.path)

    ActionDispatch::Http::UploadedFile.new(
      filename: attachment.filename,
      type: attachment.content_type,
      tempfile: temp_file
    )
  end

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