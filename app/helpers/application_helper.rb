module ApplicationHelper
  include Pagy::Frontend

  def meta_title
    [@meta_title, 'Ecosyste.ms: OpenCollective'].compact.join(' | ')
  end

  def meta_description
    @meta_description || 'An open API service for software projects hosted on Open Collective.'
  end

  def obfusticate_email(email)
    return unless email
    email.split('@').map do |part|
      # part.gsub(/./, '*') 
      part.tap { |p| p[1...-1] = "****" }
    end.join('@')
  end

  def distance_of_time_in_words_if_present(time)
    return 'N/A' unless time
    distance_of_time_in_words(time)
  end

  def rounded_number_with_delimiter(number)
    return 0 unless number
    number_with_delimiter(number.round(2))
  end

  def render_issues_chart(name, max: @max, ytitle: nil)
    content_tag :div, class: 'chart-container py-4 my-4' do
      line_chart chart_data_project_path(@project, chart: name, period: @period, exclude_bots: @exclude_bots, start_date: @start_date, end_date: @end_date), thousands: ",", title: name.humanize, max: max, ytitle: ytitle
    end
  end
end
