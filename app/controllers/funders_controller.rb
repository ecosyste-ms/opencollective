class FundersController < ApplicationController
  def index
    @funders_scope = Transaction.donations
      .group(:account)
      .select('account, SUM(amount) as total')
      .order('total DESC').to_a
    @pagy, @funders = pagy_array(@funders_scope)
  end

  def show
    @funder = params[:id]
    @transactions = Transaction.donations.where(account: @funder).includes(:collective)
    raise ActiveRecord::RecordNotFound if @transactions.empty?
    @pagy, @transactions = pagy(@transactions.order(created_at: :desc))
    @collectives = Transaction.donations.where(account: @funder).group(:collective_id).select('collective_id, SUM(amount) as total').order('total DESC').to_a
    @collective_pagy, @collectives = pagy_array(@collectives.map{|c| c.collective = Collective.find(c.collective_id); c}, page_param: :collective_page)
  end
end
