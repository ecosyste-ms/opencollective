class AuditController < ApplicationController
  def index
    redirect_to action: :user_owners
  end

  def user_owners
    @collectives = Collective.with_user_owner.order(transactions_count: :desc)
  end

  def no_projects
    @collectives = Collective.where(projects_count: 0).with_transactions.order(transactions_count: :desc).select{|c| c.project_url.present?}
  end

  def no_license
    @collectives = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && !c.projects.first.repository['archived'] && c.projects.first.repository['license'].blank?}
  end

  def archived
    @collectives = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && c.projects.first.repository['archived']}
  end

  # collectives where owner is a user instead of an org
  # collectives with invalid urls
  # collectives with inactive projects
end