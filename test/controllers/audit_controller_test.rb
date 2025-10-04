require 'test_helper'

class AuditControllerTest < ActionDispatch::IntegrationTest
  test 'duplicates logic identifies collectives with duplicate project URLs' do
    # Create collectives with duplicate project URLs
    collective1 = Collective.create!(slug: 'test-1', repository_url: 'https://github.com/test/repo', host: 'opensource')
    collective2 = Collective.create!(slug: 'test-2', repository_url: 'https://github.com/TEST/REPO', host: 'opensource')
    collective3 = Collective.create!(slug: 'test-3', repository_url: 'https://github.com/unique/repo', host: 'opensource')

    # Test the current logic
    result = Collective.opensource.all.order('transactions_count desc nulls last').select{|c| c.project_url.present?}.group_by{|c| c.project_url.downcase }.select{|k,v| v.length > 1 }.values.flatten

    # Should include duplicates but not unique
    assert_includes result.map(&:id), collective1.id
    assert_includes result.map(&:id), collective2.id
    assert_not_includes result.map(&:id), collective3.id
  end

  test 'no_projects logic identifies collectives without projects but with repo URL' do
    collective_with_repo = Collective.create!(
      slug: 'has-repo',
      repository_url: 'https://github.com/test/repo',
      projects_count: 0,
      transactions_count: 1,
      host: 'opensource'
    )
    collective_without_repo = Collective.create!(
      slug: 'no-repo',
      repository_url: nil,
      projects_count: 0,
      transactions_count: 1,
      host: 'opensource'
    )

    # Test current logic
    result = Collective.opensource.where(projects_count: 0).with_transactions.order('transactions_count desc nulls last').select{|c| c.project_url.present?}

    assert_includes result.map(&:id), collective_with_repo.id
    assert_not_includes result.map(&:id), collective_without_repo.id
  end

  test 'no_projects optimized query matches current logic' do
    collective_with_repo = Collective.create!(
      slug: 'has-repo',
      repository_url: 'https://github.com/test/repo',
      projects_count: 0,
      transactions_count: 1,
      host: 'opensource'
    )
    collective_without_repo = Collective.create!(
      slug: 'no-repo',
      repository_url: nil,
      projects_count: 0,
      transactions_count: 1,
      host: 'opensource'
    )

    # Test optimized query
    result = Collective.opensource.where(projects_count: 0).with_transactions.where.not(repository_url: nil).where.not(repository_url: '').order('transactions_count desc nulls last')

    assert_includes result.map(&:id), collective_with_repo.id
    assert_not_includes result.map(&:id), collective_without_repo.id
  end

  test 'duplicates optimized query matches current logic' do
    collective1 = Collective.create!(slug: 'test-dup-1', repository_url: 'https://github.com/test/repo', host: 'opensource')
    collective2 = Collective.create!(slug: 'test-dup-2', repository_url: 'https://github.com/TEST/REPO', host: 'opensource')
    collective3 = Collective.create!(slug: 'test-unique', repository_url: 'https://github.com/unique/repo', host: 'opensource')

    # Test optimized query
    duplicate_urls = Collective.opensource
      .where.not(repository_url: nil)
      .where.not(repository_url: '')
      .group('LOWER(repository_url)')
      .having('COUNT(*) > 1')
      .pluck('LOWER(repository_url)')

    result = Collective.opensource
      .where('LOWER(repository_url) IN (?)', duplicate_urls)
      .order('transactions_count DESC NULLS LAST')

    assert_includes result.map(&:id), collective1.id
    assert_includes result.map(&:id), collective2.id
    assert_not_includes result.map(&:id), collective3.id
  end
end
