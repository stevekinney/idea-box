require 'test_helper'

class UpdateIdeasTest < ActionDispatch::IntegrationTest

  def setup
    create_idea
    use_javascript
    visit root_path
  end

  def teardown
    reset_driver
  end

  test "promote button should promote the quality of an idea" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Plausible'
  end

  test "clicking promote button twice should promote the quality of an idea to genius" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)
    click_the_promote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Genius'
  end

  test "clicking promote button thris should not promote the quality past genius" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)
    click_the_promote_button_on_idea(idea)
    click_the_promote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Genius'
  end

  test "demoting a swill idea should keep it as swill" do
    idea = get_top_idea
    click_the_demote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Swill'
  end

  test "promoting and then demoting an idea should return it to swill" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)
    click_the_demote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Swill'
  end

  private

  def create_idea
    Idea.create(title: "Gone Soon", body: "Bye")
  end

  def get_top_idea
    page.find('.idea:first-child')
  end

  def click_the_promote_button_on_idea(idea)
    idea.find(".idea-promote").click
    wait_for_ajax
  end

  def click_the_demote_button_on_idea(idea)
    idea.find(".idea-demote").click
    wait_for_ajax
  end

end
