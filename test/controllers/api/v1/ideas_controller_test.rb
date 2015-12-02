require 'test_helper'

class Api::V1::IdeasControllerTest < ActionController::TestCase

  test "controller responds to json" do
    get :index, format: :json
    assert_response :success
  end

  test '#index returns an array of records' do
    get :index, format: :json
    assert_kind_of Array, json_response
  end

  test '#index returns the correct number of ideas' do
    get :index, format: :json

    assert_equal Idea.count, json_response.count
  end

  test '#index contains ideas with the correct properties' do
    get :index, format: :json

    json_response.each do |idea|
      assert idea["title"]
      assert idea["body"]
      assert idea["quality"]
    end
  end

  test "#show responds to json" do
    id = ideas(:one).id

    get :show, id: id, format: :json
    assert_response :success
  end

  test "#show responds with a particular idea" do
    id = ideas(:one).id

    get :show, id: id, format: :json

    assert_equal id, json_response["id"]
  end

  test '#create adds an additional idea to to the database' do
    idea = { title: 'New Idea', body: 'Something' }
    number_of_ideas = Idea.all.count

    post :create, idea: idea, format: :json

    assert_equal number_of_ideas + 1, Idea.all.count
  end

  test "#create rejects ideas without a title" do
    idea = { body: 'Something' }
    number_of_ideas = Idea.all.count

    post :create, idea: idea, format: :json

    assert_response 422
    assert_includes json_response["errors"]["title"], "can't be blank"
  end

  test "#create rejects ideas without a body" do
    idea = { title: 'New Idea' }
    number_of_ideas = Idea.all.count

    post :create, idea: idea, format: :json

    assert_response 422
    assert_includes json_response["errors"]["body"], "can't be blank"
  end


end
