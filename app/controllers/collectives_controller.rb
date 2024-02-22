class CollectivesController < ApplicationController
  def index
    scope = Collective.opensource

    if params[:sort].present? || params[:order].present?
      sort = params[:sort].presence || 'updated_at'
      if params[:order] == 'asc'
        scope = scope.order(Arel.sql(sort).asc.nulls_last)
      else
        scope = scope.order(Arel.sql(sort).desc.nulls_last)
      end
    else
      scope = scope.order('balance desc nulls last')
    end
    
    @range = (params[:range].presence || 360).to_i

    @pagy, @collectives = pagy(scope)
  end

  def batch
    @slugs = params[:slugs].try(:split, ',')
    @collectives = Collective.opensource.where(slug: @slugs).limit(20)

    @range = range
    @period = period
    @start_date = params[:start_date].presence || range.days.ago
    @end_date = params[:end_date].presence || Date.today 

    projects_scope = Project.joins(:collective).where('collectives.id in (?)', @collectives.pluck(:id))

    @pagy, @projects = pagy(projects_scope.order_by_stars)
    @transactions = Transaction.where(collective_id: @collectives.pluck(:id)).created_after(@start_date).any?
  end

  def batch_chart_data
    @slugs = params[:slugs].try(:split, ',')
    @collectives = Collective.opensource.where(slug: @slugs).limit(20)
    scope = Transaction.where(collective_id: @collectives.pluck(:id))

    data = Collective.transaction_chart_data(scope, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])
    
    render json: data
  end

  def batch_issue_chart_data
    @slugs = params[:slugs].try(:split, ',')
    @collectives = Collective.opensource.where(slug: @slugs).limit(20)
    project_ids = Project.joins(:collective).where('collectives.id in (?)', @collectives.pluck(:id)).pluck(:id)
    scope = Issue.where(project_id: project_ids)

    scope = scope.human if params[:exclude_bots] == 'true'
    scope = scope.bot if params[:only_bots] == 'true'

    data = Collective.issue_chart_data(scope, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])

    render json: data
  end

  def show
    @collective = Collective.find_by_slug!(params[:id])
    @range = range
    @period = period
    start_date = params[:start_date].presence || range.days.ago
    if @collective.projects_with_repository.length > 1
      projects_scope = @collective.projects_with_repository.active.source
    else
      projects_scope = @collective.projects_with_repository  
    end
    @pagy, @projects = pagy(projects_scope.order_by_stars)
    @transactions = @collective.transactions.created_after(start_date).any?
  end

  def funders
    @collective = Collective.find_by_slug!(params[:id])
    @funders = @collective.funders
  end

  def chart_data
    @collective = Collective.find_by_slug!(params[:id])
    
    scope = @collective.transactions

    data = Collective.transaction_chart_data(scope, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])
    
    render json: data
  end

  def charts_data
    scope = Transaction.opensource

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    data = Collective.transaction_chart_data(scope, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])
    
    render json: data
  end

  def issue_chart_data
    @collective = Collective.find_by_slug!(params[:id])
    
    scope = @collective.issues

    scope = scope.human if params[:exclude_bots] == 'true'
    scope = scope.bot if params[:only_bots] == 'true'

    data = Collective.issue_chart_data(scope, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])

    render json: data
  end

  def commit_chart_data
    @collective = Collective.find_by_slug!(params[:id])
    
    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = @collective.commits

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
    @collective = Collective.find_by_slug!(params[:id])

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today

    scope = @collective.tags

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

  def tag_charts_data
    scope = Tag.all

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    data = Rails.cache.fetch("tags_charts_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'tags'
        data = scope.group_by_period(period, :published_at).count
      end
      data
    end

    render json: data
  end

  def issue_charts_data
    scope = Issue.all

    scope = scope.human if params[:exclude_bots] == 'true'
    scope = scope.bot if params[:only_bots] == 'true'

    data = Collective.issue_chart_data(scope, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])

    render json: data
  end
end