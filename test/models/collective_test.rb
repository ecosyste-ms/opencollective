require 'test_helper'

class CollectiveTest < ActiveSupport::TestCase
  test "project_url" do
    collective = Collective.new
    collective.website = 'https://github.com/Chinachu/Chinachu'
    collective.social_links = [{"type"=>"WEBSITE", "url"=>"https://github.com/Chinachu/Chinachu"},
    {"type"=>"TWITTER", "url"=>"https://twitter.com/chinachu_rec"},
    {"type"=>"GITHUB", "url"=>"https://github.com/Chinachu"}]

    assert_equal 'https://github.com/Chinachu/Chinachu', collective.project_url
  end

  def build_collective_with_stats(owner_login:, stats:)
    collective = Collective.create!(slug: "test-#{SecureRandom.hex(4)}", host: 'opensource', owner: { 'kind' => 'user', 'login' => owner_login })
    stats.each_with_index do |s, i|
      collective.projects.create!(url: "https://github.com/#{owner_login}/repo#{i}", repository: { 'fork' => false }, commit_stats: s)
    end
    collective
  end

  test "past_year_committers merges across projects, drops bots, sums counts" do
    stats1 = { 'past_year_committers' => [
      { 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 10 },
      { 'name' => 'dependabot[bot]', 'email' => 'd@x', 'login' => 'dependabot[bot]', 'count' => 5 }
    ] }
    stats2 = { 'past_year_committers' => [
      { 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 3 },
      { 'name' => 'Bob', 'email' => 'b@x', 'login' => 'bob', 'count' => 7 }
    ] }
    collective = build_collective_with_stats(owner_login: 'alice', stats: [stats1, stats2])

    committers = collective.past_year_committers
    assert_equal 2, committers.length
    assert_equal 'alice', committers.first['login']
    assert_equal 13, committers.first['count']
    assert_equal 'bob', committers.last['login']
  end

  test "past_year_other_committers excludes owner login case-insensitively" do
    stats = { 'past_year_committers' => [
      { 'name' => 'Alice', 'email' => 'a@x', 'login' => 'Alice', 'count' => 10 },
      { 'name' => 'Bob', 'email' => 'b@x', 'login' => 'bob', 'count' => 2 }
    ] }
    collective = build_collective_with_stats(owner_login: 'alice', stats: [stats])

    assert_equal 1, collective.past_year_other_committers_count
    assert_equal 'bob', collective.past_year_other_committers.first['login']
  end

  test "owner_commit_share" do
    stats = { 'past_year_committers' => [
      { 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 90 },
      { 'name' => 'Bob', 'email' => 'b@x', 'login' => 'bob', 'count' => 10 }
    ] }
    collective = build_collective_with_stats(owner_login: 'alice', stats: [stats])

    assert_equal 90.0, collective.owner_commit_share
  end

  test "owner_commit_share is nil with no commit data" do
    collective = build_collective_with_stats(owner_login: 'alice', stats: [{ 'past_year_committers' => [] }])
    assert_nil collective.owner_commit_share
  end

  test "solo_maintainer? true when only owner committed" do
    stats = { 'past_year_committers' => [
      { 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 50 },
      { 'name' => 'renovate[bot]', 'email' => 'r@x', 'login' => 'renovate[bot]', 'count' => 20 }
    ] }
    collective = build_collective_with_stats(owner_login: 'alice', stats: [stats])

    assert_equal true, collective.solo_maintainer?
  end

  test "solo_maintainer? false when another human committed" do
    stats = { 'past_year_committers' => [
      { 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 50 },
      { 'name' => 'Bob', 'email' => 'b@x', 'login' => 'bob', 'count' => 1 }
    ] }
    collective = build_collective_with_stats(owner_login: 'alice', stats: [stats])

    assert_equal false, collective.solo_maintainer?
  end

  test "solo_maintainer? nil when no commit stats" do
    collective = Collective.create!(slug: 'no-stats', host: 'opensource', owner: { 'kind' => 'user', 'login' => 'alice' })
    assert_nil collective.solo_maintainer?
  end

  test "past_year_committers ignores forks" do
    collective = Collective.create!(slug: 'forky', host: 'opensource', owner: { 'kind' => 'user', 'login' => 'alice' })
    collective.projects.create!(url: 'https://github.com/alice/source', repository: { 'fork' => false },
      commit_stats: { 'past_year_committers' => [{ 'name' => 'Alice', 'email' => 'a@x', 'login' => 'alice', 'count' => 5 }] })
    collective.projects.create!(url: 'https://github.com/alice/fork', repository: { 'fork' => true },
      commit_stats: { 'past_year_committers' => [{ 'name' => 'Upstream', 'email' => 'u@x', 'login' => 'upstream', 'count' => 999 }] })

    assert_equal 1, collective.past_year_committers_count
    assert_equal 'alice', collective.past_year_committers.first['login']
  end

  test "committer with no login dedupes by email" do
    stats1 = { 'past_year_committers' => [{ 'name' => 'Anon', 'email' => 'anon@x', 'login' => nil, 'count' => 4 }] }
    stats2 = { 'past_year_committers' => [{ 'name' => 'Anon Different', 'email' => 'anon@x', 'login' => nil, 'count' => 6 }] }
    collective = build_collective_with_stats(owner_login: 'alice', stats: [stats1, stats2])

    assert_equal 1, collective.past_year_committers_count
    assert_equal 10, collective.past_year_committers.first['count']
  end
end
