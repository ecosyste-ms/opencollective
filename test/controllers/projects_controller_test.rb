require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test 'packages renders funding indicators when some packages have no metadata' do
    collective = Collective.create!(slug: 'funding-test', host: 'opensource')
    project = Project.create!(collective: collective, url: 'https://github.com/example/funding-project')
    [
      ['missing-metadata', {}],
      ['null-metadata', { 'metadata' => nil }],
      ['empty-metadata', { 'metadata' => {} }],
      ['funded-package', { 'metadata' => { 'funding' => 'https://example.com/sponsor' } }]
    ].each do |name, metadata|
      project.packages.create!(
        name: name,
        ecosystem: 'npm',
        metadata: {
          'registry_url' => "https://example.com/packages/#{name}",
          'versions_count' => 1
        }.merge(metadata)
      )
    end

    get packages_project_path(project)

    assert_response :success
    assert_select '.card', count: 4
    assert_select 'small[title="Accepts funding"]', count: 1
    assert_select '.card' do |cards|
      cards.each do |card|
        expected_count = card.text.include?('funded-package') ? 1 : 0
        assert_select card, 'small[title="Accepts funding"]', count: expected_count
      end
    end
  end
end
