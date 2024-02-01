require 'csv'

class AuditController < ApplicationController
  def index
    redirect_to action: :user_owners
  end

  def user_owners
    @collectives = Collective.collectives.with_user_owner.order('transactions_count desc nulls last')
  end

  def no_projects
    @collectives = Collective.collectives.where(projects_count: 0).with_transactions.order('transactions_count desc nulls last').select{|c| c.project_url.present?}
  end

  def no_license
    @collectives = Collective.collectives.with_projects.no_license.order('transactions_count desc nulls last')
  end

  def archived
    @collectives = Collective.collectives.with_projects.archived.order('transactions_count desc nulls last')
  end

  def inactive
    @collectives = Collective.collectives.with_projects.inactive.order('transactions_count desc nulls last')
  end

  def no_funding
    @collectives = Collective.collectives.with_projects.no_funding.order('transactions_count desc nulls last')
  end

  def duplicates
    @collectives = Collective.collectives.all.order('transactions_count desc nulls last').select{|c| c.project_url.present?}.group_by{|c| c.project_url.downcase }.select{|k,v| v.length > 1 }.values.flatten
  end
end