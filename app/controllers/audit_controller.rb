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
    @collectives = Collective.with_projects.no_license.order(transactions_count: :desc)
  end

  def archived
    @collectives = Collective.with_projects.archived.order(transactions_count: :desc)
  end

  def inactive
    @collectives = Collective.with_projects.inactive.order(transactions_count: :desc)
  end

  def missing_s
    @collectives = Collective.order(transactions_count: :desc).select{|c| c.missing_s? }
  end

  def no_funding
    @collectives = Collective.with_projects.no_funding.order(transactions_count: :desc)
  end

  def duplicates
    @collectives = Collective.all.order(transactions_count: :desc).select{|c| c.project_url.present?}.group_by{|c| c.project_url.downcase }.select{|k,v| v.length > 1 }.values.flatten
  end
end