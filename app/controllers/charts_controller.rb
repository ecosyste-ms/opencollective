class ChartsController < ApplicationController
  def transactions
    if params[:collective_slugs].present?
      @collectives = Collective.where(slug: params[:collective_slugs].split(',')).limit(20)
      @transactions = Transaction.where(collective: @collectives)
    else
      @transactions = Transaction.opensource
    end

    render json: Collective.transaction_chart_data(@transactions, kind: params[:chart], period: period, range: range, start_date: params[:start_date], end_date: params[:end_date])
  end
end