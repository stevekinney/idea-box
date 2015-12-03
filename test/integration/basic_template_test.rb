require 'test_helper'

class BasicTemplateTest < ActionDispatch::IntegrationTest

  test "it loads a page at the application root" do
    visit root_path
    assert_equal 200, page.status_code
  end

  test "it has an <h1> tag with the content Idea Box" do
    visit root_path
    assert page.find("h1").has_content? "Idea Box"
  end

end
