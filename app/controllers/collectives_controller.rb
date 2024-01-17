class CollectivesController < ApplicationController
  def index
    scope = Collective.all

    if params[:sort].present? || params[:order].present?
      sort = params[:sort].presence || 'updated_at'
      if params[:order] == 'asc'
        scope = scope.order(Arel.sql(sort).asc.nulls_last)
      else
        scope = scope.order(Arel.sql(sort).desc.nulls_last)
      end
    else
      scope = scope.order(balance: :desc)
    end

    @pagy, @collectives = pagy(scope)
  end

  def show
    @collective = Collective.find_by_slug!(params[:id])
    @range = (params[:range].presence || 30).to_i
  end

  def chart_data
    @collective = Collective.find_by_slug!(params[:id])
    
    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || @collective.transactions.order(:created_at).first.try(:created_at)
    end_date = params[:end_date].presence || Date.today 

    scope = @collective.transactions

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

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
    
    render json: data
  end

  def charts_data
    scope = Transaction.all

    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || 2.years.ago
    end_date = params[:end_date].presence || Date.today 

    scope = scope.created_after(start_date) if start_date.present?
    scope = scope.created_before(end_date) if end_date.present?

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
    
    render json: data
  end

  def issue_chart_data
    @collective = Collective.find_by_slug!(params[:id])
    
    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || @collective.issues.order(:created_at).first.try(:created_at) || 1.year.ago
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

  def issue_charts_data
    scope = Issue.all
    
    period = (params[:period].presence || 'month').to_sym

    start_date = params[:start_date].presence || 2.year.ago
    end_date = params[:end_date].presence || Date.today 

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
    end

    render json: data
  end


  def problems
    # collectives with no projects
    # collectives with no open source licenses

    @collectives = Collective.where(projects_count: 0).where('balance > 0').order(balance: :desc).select{|c| c.project_url.present?}

    @archived = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && c.projects.first.repository['archived']}

    @no_license = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && !c.projects.first.repository['archived'] && c.projects.first.repository['license'].blank?}
  end
end