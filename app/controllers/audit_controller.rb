require 'csv'

class AuditController < ApplicationController
  def index
    redirect_to action: :user_owners
  end

  def user_owners
    @collectives = Collective.opensource.with_user_owner.order('transactions_count desc nulls last')
  end

  def no_projects
    @collectives = Collective.opensource.where(projects_count: 0).with_transactions.where.not(repository_url: nil).where.not(repository_url: '').order('transactions_count desc nulls last')
  end

  def no_license
    @collectives = Collective.opensource.with_projects.no_license.order('transactions_count desc nulls last')
  end

  def archived
    @collectives = Collective.opensource.with_projects.archived.order('transactions_count desc nulls last')
  end

  def inactive
    @collectives = Collective.opensource.with_projects.inactive.order('transactions_count desc nulls last')
  end

  def no_funding
    @collectives = Collective.opensource.with_projects.no_funding.order('transactions_count desc nulls last')
  end

  def duplicates
    # Find duplicate repository URLs using SQL
    duplicate_urls = Collective.opensource
      .where.not(repository_url: nil)
      .where.not(repository_url: '')
      .group('LOWER(repository_url)')
      .having('COUNT(*) > 1')
      .pluck('LOWER(repository_url)')

    @collectives = Collective.opensource
      .where('LOWER(repository_url) IN (?)', duplicate_urls)
      .order('transactions_count DESC NULLS LAST')
  end
end