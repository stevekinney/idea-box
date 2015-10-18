require 'test_helper'

class IdeaTest < ActiveSupport::TestCase

  test "should have a quality that defaults to 0" do
    idea = Idea.new
    assert_equal(0, idea.quality)
  end

end
