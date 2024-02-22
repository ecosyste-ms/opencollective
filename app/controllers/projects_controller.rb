class ProjectsController < ApplicationController
  def show
    @project = Project.find(params[:id])
    @range = range
    @period = period
  end

  def index
    @scope = Project.with_repository.active

    if params[:keyword].present?
      @scope = @scope.keyword(params[:keyword])
    end

    if params[:owner].present?
      @scope = @scope.owner(params[:owner])
    end

    if params[:language].present?
      @scope = @scope.language(params[:language])
    end

    if params[:sort]
      @scope = @scope.order("#{params[:sort]} #{params[:order]}")
    else
      @scope = @scope.order_by_stars
    end

    @pagy, @projects = pagy(@scope)
  end

  def lookup
    @project = Project.find_by(url: params[:url].downcase)
    if @project.nil?
      @project = Project.create(url: params[:url].downcase)
      @project.sync_async
    end
    redirect_to @project
  end

  def tag_chart_data
    @project = Project.find(params[:id])

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today

    scope = @project.tags

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    data = Rails.cache.fetch("tags_chart_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'tags'
        data = scope.group_by_period(period, :published_at).count
      end
      data
    end

    render json: data
  end
end