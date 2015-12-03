require 'test_helper'

class DeletingIdeasTest < ActionDispatch::IntegrationTest

  def setup
<<<<<<< Updated upstream
=======
    create_idea
>>>>>>> Stashed changes
    use_javascript
    visit root_path
  end

  def teardown
    reset_driver
  end

  test "delete button removes an idea from the page" do
    assert_difference "page.find_all('.idea').count", -1 do
      page.find_all(".idea-delete").first.click

      wait_for_ajax
    end
  end

  test "delete button removes the correct idea from the page" do
    idea_div = page.find(".idea:first-child")
    idea_title = idea_div.find(".idea-title").text

    idea_div.find(".idea-delete").click

    wait_for_ajax

    refute page.has_content? idea_title
  end

  private

  def create_idea
    Idea.create(title: "Gone Soon", body: "Bye")
  end

end
