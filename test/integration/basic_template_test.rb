require 'test_helper'

class BasicTemplateTest < ActionDispatch::IntegrationTest

  test "it loads a page at the application root" do
    get "/"
    assert_response :success
  end

end
