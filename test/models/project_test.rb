require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test "github_pages_to_repo_url" do
    project = Project.new
    repo_url = project.github_pages_to_repo_url('https://foo.github.io/bar')
    assert_equal 'https://github.com/foo/bar', repo_url
  end

  test "github_pages_to_repo_url with trailing slash" do
    project = Project.new(url: 'https://foo.github.io/bar/')
    repo_url = project.repository_url
    assert_equal 'https://github.com/foo/bar', repo_url
  end

  test "fetch_commit_stats stores summary json" do
    collective = Collective.create!(slug: 'test-stats', host: 'opensource')
    project = Project.create!(url: 'https://github.com/foo/bar', collective: collective)

    body = {
      'total_commits' => 100,
      'past_year_total_committers' => 3,
      'past_year_committers' => [{ 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 90 }],
      'commits_url' => 'https://commits.ecosyste.ms/api/v1/hosts/GitHub/repositories/foo%2Fbar/commits',
      'host' => { 'name' => 'GitHub' },
      'created_at' => '2024-01-01T00:00:00Z',
      'updated_at' => '2026-01-01T00:00:00Z'
    }
    stub_request(:get, "https://commits.ecosyste.ms/api/v1/repositories/lookup?url=https://github.com/foo/bar")
      .to_return(status: 200, body: body.to_json)

    project.fetch_commit_stats
    project.reload

    assert_equal 100, project.commit_stats['total_commits']
    assert_equal 'alice', project.commit_stats['past_year_committers'].first['login']
    assert_nil project.commit_stats['commits_url']
    assert_nil project.commit_stats['host']
  end

  test "fetch_commit_stats handles 404" do
    collective = Collective.create!(slug: 'test-stats-404', host: 'opensource')
    project = Project.create!(url: 'https://github.com/foo/missing', collective: collective)

    stub_request(:get, "https://commits.ecosyste.ms/api/v1/repositories/lookup?url=https://github.com/foo/missing")
      .to_return(status: 404)

    assert_nil project.fetch_commit_stats
    assert_nil project.reload.commit_stats
  end

  test "handles nil packages_count" do
    collective = Collective.create!(slug: 'test-collective', host: 'opensource')
    project = Project.create!(url: 'https://github.com/test/repo', collective: collective)
    project.update_columns(packages_count: nil)

    # These should not raise NoMethodError
    assert_equal [], project.packages_ping_urls
    assert_equal [], project.package_funding_links
    assert_equal [], project.packages_licenses
    assert_equal 0, project.monthly_downloads
    assert_equal 0, project.downloads
    assert_equal 0, project.dependent_packages
    assert_equal 0, project.dependent_repositories
    assert_nil project.package_badge
  end
end