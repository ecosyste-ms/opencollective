class AuditController < ApplicationController
  def index
        # collectives with no projects
    # collectives with no open source licenses

    @collectives = Collective.where(projects_count: 0).where('balance > 0').order(balance: :desc).select{|c| c.project_url.present?}

    @archived = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && c.projects.first.repository['archived']}

    @no_license = Collective.where(projects_count: 1).select{|c| c.projects.first && c.projects.first.repository && !c.projects.first.repository['archived'] && c.projects.first.repository['license'].blank?}
  end
end