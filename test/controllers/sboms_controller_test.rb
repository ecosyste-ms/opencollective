require "test_helper"

class SbomsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sboms_new_url
    assert_response :success
  end

  test "should get create" do
    get sboms_create_url
    assert_response :success
  end

  test "should get index" do
    get sboms_index_url
    assert_response :success
  end

  test "should get show" do
    get sboms_show_url
    assert_response :success
  end
end
