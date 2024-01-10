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
      scope = scope.order(updated_at: :desc)
    end

    @pagy, @collectives = pagy(scope)
  end

  def show
    @collective = Collective.find_by_slug!(params[:id])
  end
end