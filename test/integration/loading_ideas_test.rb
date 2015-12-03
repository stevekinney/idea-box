require 'test_helper'

class LoadingIdeasTest < ActionDispatch::IntegrationTest

  def setup
    use_javascript
    visit root_path
  end

  def teardown
    reset_driver
  end

  test "it should load all of the ideas with an .idea div" do
    within :css, '.ideas' do
      assert_equal Idea.count, page.find_all('.idea').count
    end
  end

end
