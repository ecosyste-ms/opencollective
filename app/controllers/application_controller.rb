class ApplicationController < ActionController::Base
  skip_forgery_protection
  include Pagy::Backend

  def default_url_options(options = {})
    Rails.env.production? ? { :protocol => "https" }.merge(options) : options
  end

  private

  def range
    (params[:range].presence || 360).to_i
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

  def start_date
    params[:start_date].presence || default_start_date
  end

  def end_date
    params[:end_date].presence || default_end_date
  end

  def default_end_date    
    case period
    when :day
      1.day.ago.end_of_day
    when :week
      1.week.ago.end_of_week
    when :month
      1.month.ago.end_of_month
    when :year
      1.year.ago.end_of_year
    end
  end

  def default_start_date
    default_end_date - range.days
  end
end
