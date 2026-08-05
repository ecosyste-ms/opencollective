require 'test_helper'

class CacheHeadersTest < ActionDispatch::IntegrationTest
  test 'html pages set public cache headers with s-maxage' do
    get '/funders'
    assert_response :success
    cache_control = response.headers['Cache-Control']
    assert_match(/public/, cache_control)
    assert_match(/max-age=300/, cache_control)
    assert_match(/s-maxage=21600/, cache_control)
  end

  test 'html pages do not set cookies' do
    get '/funders'
    assert_response :success
    assert_nil response.headers['Set-Cookie']
  end

  test 'collective show does not set cookies' do
    collective = Collective.create!(slug: 'cookie-test', host: 'opensource')
    get collective_path(collective)
    assert_response :success
    assert_nil response.headers['Set-Cookie']
  end
end
