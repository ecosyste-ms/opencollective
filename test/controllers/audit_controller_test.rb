require 'test_helper'

class AuditControllerTest < ActionDispatch::IntegrationTest
  test 'no_projects lists collectives whose project_url derives from social_links' do
    with_link = Collective.create!(
      slug: 'has-repo', host: 'opensource', projects_count: 0, transactions_count: 1,
      repository_url: nil, balance: nil, currency: 'USD',
      social_links: [{ 'type' => 'GITHUB', 'url' => 'https://github.com/test/repo' }]
    )
    Collective.create!(slug: 'no-repo', host: 'opensource', projects_count: 0, transactions_count: 1,
      repository_url: nil, balance: 0, currency: 'USD')

    get '/audit/no_projects'
    assert_response :success
    assert_includes assigns(:collectives).map(&:id), with_link.id
    assert_match 'has-repo', response.body
    assert_no_match 'no-repo', response.body

    get '/audit/no_projects.csv'
    assert_response :success
    assert_match 'has-repo,https://github.com/test/repo', response.body
  end

  test 'duplicates matches on derived project_url across github and social_links' do
    dup1 = Collective.create!(slug: 'dup-1', host: 'opensource', repository_url: nil, balance: nil, currency: 'USD', github: 'test/repo')
    dup2 = Collective.create!(slug: 'dup-2', host: 'opensource', repository_url: nil, balance: 0, currency: 'USD',
      social_links: [{ 'type' => 'GITHUB', 'url' => 'https://github.com/TEST/REPO' }])
    Collective.create!(slug: 'unique', host: 'opensource', repository_url: nil, balance: 0, currency: 'USD', github: 'other/repo')

    get '/audit/duplicates'
    assert_response :success
    ids = assigns(:collectives).map(&:id)
    assert_includes ids, dup1.id
    assert_includes ids, dup2.id
    assert_match 'dup-1', response.body
    assert_no_match 'unique', response.body
  end

  test 'user_owners renders with commit stats' do
    collective = Collective.create!(slug: 'solo', host: 'opensource', balance: nil, currency: 'USD',
      owner: { 'kind' => 'user', 'login' => 'alice', 'html_url' => 'https://github.com/alice', 'repositories_count' => 1 })
    collective.projects.create!(url: 'https://github.com/alice/thing', repository: { 'fork' => false },
      commit_stats: { 'past_year_committers' => [{ 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 50 }] })

    get '/audit/user_owners'
    assert_response :success
    assert_match 'solo', response.body

    get '/audit/user_owners.csv'
    assert_response :success
    assert_match 'solo_maintainer', response.body
    assert_match 'solo,alice', response.body
    assert_match 'true', response.body
  end

end
