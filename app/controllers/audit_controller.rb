require 'csv'

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
    @collectives = Collective.with_projects.order(transactions_count: :desc).select{|c| c.no_license? }
  end

  def archived
    @collectives = Collective.with_projects.order(transactions_count: :desc).select{|c| c.archived? }
  end

  def inactive
    @collectives = Collective.with_projects.order(transactions_count: :desc).select{|c| c.inactive? }
  end

  # collectives with no funding links
  # collectives with invalid urls
end