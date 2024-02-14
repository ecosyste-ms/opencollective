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

    projects_scope = Project.joins(:collectives).where('collectives.id in (?)', @collectives.pluck(:id))

    @pagy, @projects = pagy(projects_scope.order_by_stars)
    @transactions = Transaction.where(collective_id: @collectives.pluck(:id)).created_after(@start_date).any?
  end

  def batch_chart_data
    @slugs = params[:slugs].try(:split, ',')
    @collectives = Collective.opensource.where(slug: @slugs).limit(20)
    scope = Transaction.where(collective_id: @collectives.pluck(:id))

    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    data = Rails.cache.fetch("charts_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'all_transactions'
        data = scope.group_by_period(period, :created_at).sum(:net_amount)
      when 'expenses'
        data = scope.expenses.group_by_period(period, :created_at).sum(:net_amount).map{|k,v| [k, -v]}.to_h
      when 'donations'
        data = scope.donations.group_by_period(period, :created_at).sum(:net_amount)
      when 'unique_donors'
        data = scope.donations.group_by_period(period, :created_at).distinct.count(:account)
      when 'unique_expenses'
        data = scope.expenses.group_by_period(period, :created_at).distinct.count(:account)
      when 'donations_and_expenses'
        data = [
          {name: 'Donations', data: scope.donations.group_by_period(period, :created_at).sum(:net_amount)},
          {name: 'Expenses', data: scope.expenses.group_by_period(period, :created_at).sum(:net_amount).map{|k,v| [k, -v]}},
          ]
      when 'unique_donors_and_spenders'
        data = [
          {name: 'Donors', data: scope.donations.group_by_period(period, :created_at).distinct.count(:account)},
          {name: 'Spenders', data: scope.expenses.group_by_period(period, :created_at).distinct.count(:account)}
          ]
      end
      data
    end
    
    render json: data
  end

  def batch_issue_chart_data
    @slugs = params[:slugs].try(:split, ',')
    @collectives = Collective.opensource.where(slug: @slugs).limit(20)
    project_ids =Project.joins(:collectives).where('collectives.id in (?)', @collectives.pluck(:id)).pluck(:id)
    scope = Issue.where(project_id: project_ids)
    
    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    if params[:exclude_bots] == 'true'
      scope = scope.human
    end

    if params[:only_bots] == 'true'
      scope = scope.bot
    end

    data = Rails.cache.fetch("issue_charts_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'issues_opened'
        data = scope.issue.group_by_period(period, :created_at).count
      when 'issues_closed'
        data = scope.issue.closed.group_by_period(period, :closed_at).count
      when 'issue_authors'
        data = scope.issue.group_by_period(period, :created_at).distinct.count(:user)
      when 'issue_average_time_to_close'
        data = scope.issue.closed.group_by_period(period, :closed_at).average(:time_to_close)
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
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
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
      when 'pull_request_average_time_to_merge'
        data = scope.pull_request.merged.group_by_period(period, :merged_at).average(:time_to_close)
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
      end
      data
    end

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
    
    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = @collective.transactions

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    data = Rails.cache.fetch("chart_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'all_transactions'
        data = scope.group_by_period(period, :created_at).sum(:net_amount)
      when 'expenses'
        data = scope.expenses.group_by_period(period, :created_at).sum(:net_amount).map{|k,v| [k, -v]}.to_h
      when 'donations'
        data = scope.donations.group_by_period(period, :created_at).sum(:net_amount)
      when 'unique_donors'
        data = scope.donations.group_by_period(period, :created_at).distinct.count(:account)
      when 'unique_expenses'
        data = scope.expenses.group_by_period(period, :created_at).distinct.count(:account)
      end
      data
    end
    
    render json: data
  end

  def charts_data
    scope = Transaction.opensource

    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    data = Rails.cache.fetch("charts_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'all_transactions'
        data = scope.group_by_period(period, :created_at).sum(:net_amount)
      when 'expenses'
        data = scope.expenses.group_by_period(period, :created_at).sum(:net_amount).map{|k,v| [k, -v]}.to_h
      when 'donations'
        data = scope.donations.group_by_period(period, :created_at).sum(:net_amount)
      when 'unique_donors'
        data = scope.donations.group_by_period(period, :created_at).distinct.count(:account)
      when 'unique_expenses'
        data = scope.expenses.group_by_period(period, :created_at).distinct.count(:account)
      when 'donations_and_expenses'
        data = [
          {name: 'Donations', data: scope.donations.group_by_period(period, :created_at).sum(:net_amount)},
          {name: 'Expenses', data: scope.expenses.group_by_period(period, :created_at).sum(:net_amount).map{|k,v| [k, -v]}},
          ]
      when 'unique_donors_and_spenders'
        data = [
          {name: 'Donors', data: scope.donations.group_by_period(period, :created_at).distinct.count(:account)},
          {name: 'Spenders', data: scope.expenses.group_by_period(period, :created_at).distinct.count(:account)}
          ]
      when 'new_collectives'
        data = Collective.opensource.group_by_period(period, :collective_created_at).count
      end
      data
    end
    
    render json: data
  end

  def issue_chart_data
    @collective = Collective.find_by_slug!(params[:id])
    
    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = @collective.issues

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    if params[:exclude_bots] == 'true'
      scope = scope.human
    end

    if params[:only_bots] == 'true'
      scope = scope.bot
    end

    data = Rails.cache.fetch("issue_chart_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'issues_opened'
        data = scope.issue.group_by_period(period, :created_at).count
      when 'issues_closed'
        data = scope.issue.closed.group_by_period(period, :closed_at).count
      when 'issue_authors'
        data = scope.issue.group_by_period(period, :created_at).distinct.count(:user)
      when 'issue_average_time_to_close'
        data = scope.issue.closed.group_by_period(period, :closed_at).average(:time_to_close)
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
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
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
      when 'pull_request_average_time_to_merge'
        data = scope.pull_request.merged.group_by_period(period, :merged_at).average(:time_to_close)
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
      when 'maintainers'
        data = scope.maintainers.group_by_period(period, :created_at).distinct.count(:user)
      end
      data
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

  def issue_charts_data
    scope = Issue.all
    
    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || range.days.ago
    end_date = params[:end_date].presence || Date.today 

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

    if params[:exclude_bots] == 'true'
      scope = scope.human
    end

    if params[:only_bots] == 'true'
      scope = scope.bot
    end

    data = Rails.cache.fetch("issue_charts_data:#{params}", expires_in: 1.day) do
      case params[:chart]
      when 'issues_opened'
        data = scope.issue.group_by_period(period, :created_at).count
      when 'issues_closed'
        data = scope.issue.closed.group_by_period(period, :closed_at).count
      when 'issue_authors'
        data = scope.issue.group_by_period(period, :created_at).distinct.count(:user)
      when 'issue_average_time_to_close'
        data = scope.issue.closed.group_by_period(period, :closed_at).average(:time_to_close)
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
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
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
      when 'pull_request_average_time_to_merge'
        data = scope.pull_request.merged.group_by_period(period, :merged_at).average(:time_to_close)
        data.update(data){ |_,v| v.to_f.seconds.in_days.round(1) }
      when 'maintainers'
        data = scope.maintainers.group_by_period(period, :created_at).distinct.count(:user)
      end
      data
    end

    render json: data
  end
end