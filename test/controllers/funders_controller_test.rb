require 'test_helper'

class FundersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @collective = Collective.create!(slug: 'test-collective', host: 'opensource')
    Transaction.create!(collective: @collective, uuid: 'tx-1', account: 'acme', amount: 10.0, net_amount: 9.0, currency: 'USD', transaction_type: 'CREDIT')
  end

  test 'index renders' do
    get '/funders'
    assert_response :success
    assert_match 'acme', response.body
  end

  test 'index with overflowing page param returns 404' do
    get '/funders?page=9999'
    assert_response :not_found
  end
end
