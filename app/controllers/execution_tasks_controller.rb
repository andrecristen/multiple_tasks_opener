class ExecutionTasksController < ApplicationController
  before_action :find_issue

  def new
    # Carregar as configurações do plugin com base no tracker_origin
    @config = load_config(@issue.tracker_id)
  end

  def create
    # Criar as tarefas relacionadas com base na configuração e nas entradas do usuário
    create_related_tasks(params[:related_tasks])
    flash[:notice] = 'Tarefas de Execução geradas com sucesso!'
    redirect_to @issue
  end

  private

  def find_issue
    @issue = Issue.find(params[:parent_issue_id])
  end

  def load_config(tracker_origin)
    # Carrega a configuração do plugin
    config = Setting.plugin_multiple_tasks_opener['open_issues']
    # Garante que a configuração existe e é um Hash
    return [] unless config.is_a?(Hash)
    # Procura dentro da configuração um item onde o tracker_origin corresponde ao informado
    config.each_value do |entry|
      return entry['related_trackers'].values if entry['tracker_origin'].to_s == tracker_origin.to_s
    end
    # Retorna um array vazio caso não encontre nenhuma correspondência
    []
  end

  def create_related_tasks(related_tasks)
    # Aqui você cria as tarefas relacionadas com base nas entradas do usuário
    related_tasks.each do |task|
      Issue.create(
        project_id: @issue.project_id,
        tracker_id: task[:type],
        subject: task[:template],
        description: task[:description],
        parent_id: @issue.id
      )
    end
  end
end