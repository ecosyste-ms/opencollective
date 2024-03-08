module Stats
  extend ActiveSupport::Concern

  class_methods do
    def new_issues_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.issue.between(start_date, end_date).count, 0]
    end

    def new_pull_requests_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.pull_request.between(start_date, end_date).count, 0]
    end

    def closed_issues_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.issue.closed_between(start_date, end_date).count, 0]
    end

    def merged_pull_requests_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.pull_request.merged_between(start_date, end_date).count, 0]
    end

    def open_issues(collective_slugs: nil, project_ids: nil, range:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.issue.this_period(range).count, issues.issue.last_period(range).count]
    end

    def open_pull_requests(collective_slugs: nil, project_ids: nil, range:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.pull_request.this_period(range).count, issues.pull_request.last_period(range).count]
    end

    def closed_issues(collective_slugs: nil, project_ids: nil, range:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.issue.closed_this_period(range).count, issues.issue.closed_last_period(range).count]
    end

    def closed_pull_requests_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.pull_request.not_merged.closed_between(start_date, end_date).count, 0]
    end

    def issue_authors_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.issue.between(start_date, end_date).distinct.count(:user), 0]
    end

    def pull_request_authors_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.pull_request.between(start_date, end_date).distinct.count(:user), 0]
    end

    def avg_issue_time_to_close(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.issue.closed_between(start_date, end_date).average(:time_to_close), 0]
    end

    def avg_pr_time_to_merge(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.pull_request.merged_between(start_date, end_date).average(:time_to_close), 0]
    end

    def avg_pr_time_to_close(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.pull_request.closed_between(start_date, end_date).average(:time_to_close), 0]
    end

    def active_maintainers_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      issues = issues_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [issues.maintainers.between(start_date, end_date).distinct.count(:user), 0]
    end

    def issues_scope(collective_slugs: nil, project_ids: nil)
      if collective_slugs.present?
        collectives = Collective.where(slug: collective_slugs.split(',')).limit(20)
        issues = Issue.where(project_id: Project.where(collective: collectives).pluck(:id))
      elsif project_ids.present?
        issues = Issue.where(project_id: project_ids.to_s.split(','))
      else
        issues = Issue.all
      end
    end

    def transactions_scope(collective_slugs: nil, project_ids: nil)
      if collective_slugs.present?
        collectives = Collective.where(slug: collective_slugs.split(',')).limit(20)
        transactions = Transaction.where(collective_id: collectives.pluck(:id)).not_host_fees
      elsif project_ids.present?
        []
      end
    end

    def transactions_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.between(start_date, end_date).count, 0]
    end

    def transactions_total_amount(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.between(start_date, end_date).sum(:amount), 0]
    end

    def expenses_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.expenses.between(start_date, end_date).count, 0]
    end

    def expenses_total_amount(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.expenses.between(start_date, end_date).sum(:amount), 0]
    end

    def donations_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.donations.between(start_date, end_date).count, 0]
    end

    def donations_total_amount(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.donations.between(start_date, end_date).sum(:amount), 0]
    end

    def unique_donors_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.donations.between(start_date, end_date).distinct.count(:account), 0]
    end

    def unique_spenders_count(collective_slugs: nil, project_ids: nil, start_date: , end_date:)
      transactions = transactions_scope(collective_slugs: collective_slugs, project_ids: project_ids)
      [transactions.expenses.between(start_date, end_date).distinct.count(:account), 0]
    end

  end

  def open_issues(range:)
    [self.issues.issue.this_period(range).count, self.issues.issue.last_period(range).count]
  end
end