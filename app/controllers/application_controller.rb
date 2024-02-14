class ApplicationController < ActionController::Base
  skip_forgery_protection
  include Pagy::Backend

  def default_url_options(options = {})
    Rails.env.production? ? { :protocol => "https" }.merge(options) : options
  end

  private

  def range
    (params[:range].presence || 30).to_i
  end

  def period
    case range
    when 0..30
      (params[:period].presence || 'day').to_sym
    when 31..90
      (params[:period].presence || 'week').to_sym
    when 91..365
      (params[:period].presence || 'month').to_sym
    else
      (params[:period].presence || 'year').to_sym
    end
  end
end
