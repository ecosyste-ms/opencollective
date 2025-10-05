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