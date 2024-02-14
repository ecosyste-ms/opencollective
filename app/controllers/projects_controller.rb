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
    
    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = @project.issues

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    if params[:exclude_bots] == 'true'
      scope = scope.human
    end

    if params[:only_bots] == 'true'
      scope = scope.bot
    end

    case params[:chart]
    when 'issues_opened'
      data = scope.issue.group_by_period(period, :created_at).count
    when 'issues_closed'
      data = scope.issue.closed.group_by_period(period, :closed_at).count
    when 'issue_authors'
      data = scope.issue.group_by_period(period, :created_at).distinct.count(:user)
    when 'issue_average_time_to_close'
      data = scope.issue.closed.group_by_period(period, :closed_at).average(:time_to_close)
      data.update(data){ |_,v| v.to_f.seconds.in_days.to_i }
    when 'pull_requests_opened'
      data = scope.pull_request.group_by_period(period, :created_at).count
    when 'pull_requests_closed'
      data = scope.pull_request.group_by_period(period, :closed_at).count
    when 'pull_requests_merged'
      data = scope.pull_request.merged.group_by_period(period, :merged_at).count
    when 'pull_requests_not_merged'
      data = scope.pull_request.not_merged.group_by_period(period, :closed_at).count
    when 'pull_request_authors'
      data = scope.pull_request.group_by_period(period, :created_at).distinct.count(:user)
    when 'pull_request_average_time_to_close'
      data = scope.pull_request.closed.group_by_period(period, :closed_at).average(:time_to_close)
      data.update(data){ |_,v| v.to_f.seconds.in_days.to_i }
    when 'pull_request_average_time_to_merge'
      data = scope.pull_request.merged.group_by_period(period, :merged_at).average(:time_to_close)
      data.update(data){ |_,v| v.to_f.seconds.in_days.to_i }
    when 'maintainers'
      data = scope.maintainers.group_by_period(period, :created_at).distinct.count(:user)
    end
    
    ## TODO no data for these yet
    # Number of issue comments
    # Average number of comments per issue
    # Number of pull request comments
    # Average number of comments per pull request
    # Average time to first issue response
    # Average time to first pull request response
    # Number of new issue authors
    # Number of new pull request authors

    render json: data
  end
end