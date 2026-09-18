require 'test_helper'

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test 'renders 404' do
    get '/404'
    assert_response :not_found
    assert_template 'errors/not_found'
  end

  test 'renders 422' do
    get '/422'
    assert_response :unprocessable_content
    assert_template 'errors/unprocessable'
  end

  test 'renders 500 with no-store' do
    get '/500'
    assert_response :internal_server_error
    assert_template 'errors/internal'
    assert_equal 'no-store', response.headers['Cache-Control']
  end

  test 'error responses do not carry public cache headers' do
    get '/404'
    assert_no_match 'public', response.headers['Cache-Control'].to_s
    assert_no_match 's-maxage', response.headers['Cache-Control'].to_s
  end
end