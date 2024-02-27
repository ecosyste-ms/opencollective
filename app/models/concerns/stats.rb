module Stats
  extend ActiveSupport::Concern

  class_methods do
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
  end

  def open_issues(range:)
    [self.issues.issue.this_period(range).count, self.issues.issue.last_period(range).count]
  end
end