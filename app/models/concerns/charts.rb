module Charts
  extend ActiveSupport::Concern

  class_methods do

    def transaction_chart_data(scope, kind:, period:, range:, start_date:, end_date:)
      start_date = start_date.presence || range.days.ago
      end_date = end_date.presence || Date.today 

      scope = scope.created_after(start_date) if start_date.present?
      scope = scope.created_before(end_date) if end_date.present?

      # TODO caching
      case kind
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
        scope = Collective.opensource
        scope = scope.where('collective_created_at >= ?', start_date) if start_date.present?
        scope = scope.where('collective_created_at <= ?', end_date) if end_date.present?

        data = scope.group_by_period(period, :collective_created_at).count
      end
      
      return data
    end

    def issue_chart_data(scope, kind:, period:, range:, start_date:, end_date:)
      start_date = start_date.presence || range.days.ago
      end_date = end_date.presence || Date.today 

      scope = scope.created_after(start_date) if start_date.present?
      scope = scope.created_before(end_date) if end_date.present?

      # TODO caching
      case kind
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
      
      ## TODO no data for these yet
      # Number of issue comments
      # Average number of comments per issue
      # Number of pull request comments
      # Average number of comments per pull request
      # Average time to first issue response
      # Average time to first pull request response
      # Number of new issue authors
      # Number of new pull request authors

      return data
    end
  end
end