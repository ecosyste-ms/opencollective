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
      scope = scope.order(transactions_count: :desc)
    end

    @pagy, @collectives = pagy(scope)
  end

  def show
    @collective = Collective.find_by_slug!(params[:id])
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
end