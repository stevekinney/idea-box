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

  test "it has an ideas container on the page" do
    visit root_path
    assert page.has_css? ".ideas"
  end

  test "it has a form for creating new ideas" do
    visit root_path
    assert page.has_css? "form.new-idea"
  end

  test "form has an text input for a new idea title" do
    visit root_path
    assert page.has_css? "form.new-idea input[type='text'].new-idea-title"
  end

  test "form has an text input for a new idea button" do
    visit root_path
    assert page.has_css? "form.new-idea input[type='text'].new-idea-body"
  end

  test "form has an input button" do
    visit root_path
    assert page.has_css? "form.new-idea input[type='submit'].new-idea-submit"
  end

end
