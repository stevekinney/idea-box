require 'test_helper'

class DeletingIdeasTest < ActionDispatch::IntegrationTest

  def setup
    use_javascript
    visit root_path
  end

  def teardown
    reset_driver
  end

  test "delete button removes an idea from the page" do
    create_idea_by_filling_out_form

    assert_difference "page.find_all('.idea').count", -1 do
      page.find_all(".idea-delete").first.click

      wait_for_ajax
    end
  end

  test "delete button removes the correct idea from the page" do
    create_idea_by_filling_out_form

    idea_div = page.find(".idea:first-child")
    idea_title = idea_div.find(".idea-title").text

    idea_div.find(".idea-delete").click

    wait_for_ajax

    refute page.has_content? idea_title
  end

  private

  def create_idea_by_filling_out_form
    page.fill_in "idea[title]", with: "Gone Soon"
    page.fill_in "idea[body]", with: "Bye"
    page.click_button "Submit Idea"

    wait_for_ajax
  end

end
