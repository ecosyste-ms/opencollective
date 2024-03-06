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
    
    @period = period
    @range = range
    @interval = interval
    @end_date = 1.month.ago.end_of_month
    @start_date = 1.year.ago

    @pagy, @collectives = pagy(scope)
  end

  def batch
    @slugs = params[:slugs].try(:split, ',')
    @collectives = Collective.opensource.where(slug: @slugs).limit(20)

    @range = range
    @period = period
    @start_date = start_date
    @end_date = end_date

    projects_scope = Project.joins(:collective).where('collectives.id in (?)', @collectives.pluck(:id))

    @pagy, @projects = pagy(projects_scope.order_by_stars)
    @transactions = Transaction.where(collective_id: @collectives.pluck(:id)).created_after(@start_date).any?
  end

  def show
    @collective = Collective.find_by_slug!(params[:id])
    @range = range
    @period = period
    @start_date = start_date
    @end_date = end_date
    @interval = interval
  end

  def funders
    @collective = Collective.find_by_slug!(params[:id])
    @funders = @collective.funders
  end

  def projects
    @collective = Collective.find_by_slug!(params[:id])
    @pagy, @projects = pagy(@collective.projects_with_repository.active.source.order_by_stars)
  end

  def packages
    @collective = Collective.find_by_slug!(params[:id])
    @pagy, @packages = pagy(@collective.packages.includes(:project).active)
  end

  def issues
    @collective = Collective.find_by_slug!(params[:id])
    @pagy, @issues = pagy(@collective.issues.includes(:project).order('created_at DESC'))
  end

  def releases
    @collective = Collective.find_by_slug!(params[:id])
    @pagy, @releases = pagy(@collective.tags.includes(:project).order('published_at DESC'))
  end

  def commits
    @collective = Collective.find_by_slug!(params[:id])
    @pagy, @commits = pagy(@collective.commits.includes(:project).order('timestamp DESC'))
  end

  def transactions
    @collective = Collective.find_by_slug!(params[:id])
    @pagy, @transactions = pagy(@collective.transactions.order('created_at DESC'))
  end
end