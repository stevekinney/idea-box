require 'test_helper'

class Api::V1::IdeasControllerTest < ActionController::TestCase

  test "controller responds to json" do
    get :index, format: :json
    assert_response :success
  end

  test 'index returns an array of records' do
    get :index, format: :json
    assert_kind_of Array, json_response
  end

end
