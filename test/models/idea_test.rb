require 'test_helper'

class IdeaTest < ActiveSupport::TestCase

  test "should have a quality that defaults to 0" do
    idea = Idea.new
    assert_equal("swill", idea.quality)
  end

  test "it should be invalid without a title" do
    idea_without_title = Idea.new
    idea_with_title = Idea.new(title: "My greatest idea")

    refute(idea_without_title.valid?)
    assert(idea_with_title.valid?)
  end

end
