require 'test_helper'

class LoadingIdeasTest < ActionDispatch::IntegrationTest

  def setup
    super
    use_javascript
    visit root_path
  end

  def teardown
    super
    reset_driver
  end

  test "it creates a new idea upon form submission" do
    assert_difference 'Idea.count', 1 do
      page.fill_in "idea[title]", with: 'Special Idea'
      page.fill_in "idea[body]", with: 'World domination'
      page.click_button "Submit Idea"
      wait_for_ajax
    end
  end

end
