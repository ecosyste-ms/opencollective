class AuditController < ApplicationController
  def index
    @collectives = Collective.where(projects_count: 0).where('balance > 0').order(balance: :desc).select{|c| c.project_url.present?}

    @archived = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && c.projects.first.repository['archived']}

    @no_license = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && !c.projects.first.repository['archived'] && c.projects.first.repository['license'].blank?}
  end

  # collectives where owner is a user instead of an org
  # collectives with invalid urls
  # collectives with no projects
  # collectives with inactive projects
end