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
end