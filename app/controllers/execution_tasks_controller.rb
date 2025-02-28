class ExecutionTasksController < IssuesController
  before_action :find_issue, only: [:new, :create]
  before_action :set_project
  before_action :set_priorities
  before_action :set_versions
  before_action :authorize, only: [:new, :create]

  helper :issues
  include IssuesHelper

  def new
    @config = load_config(@issueOrigin.tracker_id)
  end

  def create
    related_tasks = params[:related_tasks]
    if related_tasks.blank?
      flash[:error] = 'Formato inválido para tarefas relacionadas'
      return redirect_to @issueOrigin
    end
    begin
      ActiveRecord::Base.transaction do
        created_tasks = []
        related_tasks.each do |_key, task|
          new_task = create_issue(task)
          unless new_task.save
            flash[:error] ||= "Erro ao criar tarefa ["+task['subject'] || @issueOrigin.subject+"]: <ul>"
            flash[:error] += new_task.errors.full_messages.map { |message| "<li>#{message}</li>" }.join
            flash[:error] += "</ul>"
            raise ActiveRecord::Rollback
          end
          create_attachments_issue(new_task, task)
          create_relationship(@issueOrigin, new_task, task['relationship_type']) if task['relationship_type'] != "subtask"
          created_tasks << new_task
        end
        flash[:notice] = 'Tarefas de Execução geradas com sucesso!'
        redirect_to @issueOrigin
      end
    rescue => e
      flash[:error] ||= "Ocorreu um erro ao criar as tarefas: #{e.message}"
      @related_tasks = related_tasks
      @config = load_config(@issueOrigin.tracker_id)
      render :new
    end
  end

  private

  def create_issue(task)
    Issue.new(
      project_id: @issueOrigin.project_id,
      tracker_id: task['type'],
      subject: task['subject'] || @issueOrigin.subject,
      description: task['description'],
      assigned_to_id: task['assigned_to_id'] || @issueOrigin.assigned_to_id,
      estimated_hours: task['estimated_hours'] || @issueOrigin.estimated_hours,
      start_date: @issueOrigin.start_date,
      due_date: @issueOrigin.due_date,
      priority_id: @issueOrigin.priority_id,
      status_id: @issueOrigin.status_id,
      author_id: User.current.id,
      parent_id: task['relationship_type'] == "subtask" ? @issueOrigin.id : nil,
      custom_field_values: format_custom_fields(task),
      fixed_version_id: @issueOrigin.fixed_version_id,
      category_id: @issueOrigin.category_id
    )
  end

  def format_custom_fields(task)
    custom_field_values = {}
    if task['custom_field_values'].present?
      task['custom_field_values'].each do |key, value|
        custom_field = CustomField.find_by(id: key.to_i)
        if custom_field
          if custom_field.is_required? && value.blank?
            flash[:error] ||= ""
            flash[:error] += "O campo obrigatório '#{custom_field.name}' não foi preenchido. <br/>"
            return nil
          end
          if value && value.length > 0
            custom_field_values[key] = value
          end
        end
      end
    end
    custom_field_values
  end

  def create_relationship(origin, target, relation_type)
    relation = IssueRelation.new(
      issue_from: origin,
      issue_to: target,
      relation_type: relation_type
    )
    unless relation.save
      flash[:error] ||= "Erro ao criar relação entre as tarefas: <ul>"
      flash[:error] += "<li>#{relation.errors.full_messages.join(', ')}</li>"
      flash[:error] += "</ul>"
    end
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
    @issueOrigin = Issue.find_by(id: params[:open_from])
    raise ActiveRecord::RecordNotFound, "Atividade não encontrada" if @issueOrigin.nil?
    @parent_issue_author = @issueOrigin.author&.name
    @parent_issue_assigned_to = @issueOrigin.assigned_to&.name
  end

  def set_project
    @project = @issueOrigin.project
  end

  def set_priorities
    @priorities = IssuePriority.active
  end

  def set_versions
    @versions = @issueOrigin.assignable_versions
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