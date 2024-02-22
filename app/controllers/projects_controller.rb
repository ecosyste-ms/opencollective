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

  def chart_data
    @project = Project.find(params[:id])

    scope = @project.issues

    scope = scope.human if params[:exclude_bots] == 'true'
    scope = scope.bot if params[:only_bots] == 'true'

    data = Collective.issue_chart_data(scope, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])

    render json: data
  end

  def commit_chart_data
    @project = Project.find(params[:id])
    
    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = @project.commits

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    data = Rails.cache.fetch("commit_chart_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'commits'
        data = scope.group_by_period(period, :timestamp).count
      when 'merge_commits'
        data = scope.merges.group_by_period(period, :timestamp).count
      when 'commit_authors'
        data = scope.group_by_period(period, :timestamp).distinct.count(:author)
      when 'commit_committers'
        data = scope.group_by_period(period, :timestamp).distinct.count(:committer)
      end
      data
    end

    render json: data
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