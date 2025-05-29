class Api::V1::ProjectsController < Api::V1::ApplicationController
  def index
    if params[:collective_id].present?
      @collective = Collective.find_by_slug!(params[:collective_id])
      @projects = @collective.projects.where.not(last_synced_at: nil).includes(:collective, :tags)
    else
      @projects = Project.all.where.not(last_synced_at: nil).includes(:collective, :tags)
    end
    @pagy, @projects = pagy(@projects)
  end

  def show
    if params[:collective_id].present?
      @collective = Collective.find_by_slug!(params[:collective_id])
      @project = @collective.projects.find(params[:id])
    else
      @project = Project.find(params[:id])
    end
  end

  def lookup
    @project = Project.find_by(url: params[:url].downcase)
    raise ActiveRecord::RecordNotFound unless @project
  end

  def ping
    @project = Project.find(params[:id])
    @project.sync_async
    render json: { message: 'pong' }
  end
end