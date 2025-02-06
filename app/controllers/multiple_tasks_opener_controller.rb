class MultipleTasksOpenerController < ApplicationController
  before_action :require_admin

  def settings
    # Verificar se existem categorias de atividades (IssueCategory) e definir @activity_types adequadamente
    @activity_types = IssueCategory.all.map { |category| [category.name, category.id] } if IssueCategory.exists?
    @activity_types ||= []  # Se não houver categorias, inicializar como uma lista vazia

    @selected_activity_type = Setting.plugin_multiple_tasks_opener[:base_activity_type]
    @selected_related_activity_type = Setting.plugin_multiple_tasks_opener[:related_activity_type]
  end

  def save_settings
    Setting.plugin_multiple_tasks_opener[:base_activity_type] = params[:base_activity_type]
    Setting.plugin_multiple_tasks_opener[:related_activity_type] = params[:related_activity_type]
    flash[:notice] = "Configurações salvas com sucesso!"
    redirect_to settings_plugin_multiple_tasks_opener_path
  end
end
