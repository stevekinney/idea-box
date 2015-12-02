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

  test "#create adds an additional idea to to the database" do
    assert_difference 'Idea.count', 1 do
      idea = { title: "New Idea", body: "Something" }

      post :create, idea: idea, format: :json
    end
  end

  test "#create returns the new idea" do
    idea = { title: "New Idea", body: "Something" }

    post :create, idea: idea, format: :json

    assert_equal idea[:title], json_response["title"]
    assert_equal idea[:body], json_response["body"]
    assert_equal "swill", json_response["quality"]
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

  test "#update an idea through" do
    updated_content = { title: "Updated Idea", body: "Something" }

    put :update, id: ideas(:one), idea: updated_content, format: :json

    ideas(:one).reload
    assert_equal "Updated Idea", ideas(:one).title
  end

  test "#update an idea through the API" do
    updated_content = { title: "Updated Idea", body: "Something" }

    put :update, id: ideas(:one), idea: updated_content, format: :json
    ideas(:one).reload

    assert_equal "Updated Idea", ideas(:one).title
  end

  test "#update the quality of an idea" do
    updated_content = { quality: "plausible" }

    put :update, id: ideas(:one), idea: updated_content, format: :json
    ideas(:one).reload

    assert_equal "plausible", ideas(:one).quality
  end

  test "#update rejects invalid quality values" do
    updated_content = { quality: "invalid" }

    put :update, id: ideas(:one), idea: updated_content, format: :json

    assert_response 422
  end

  test "#destroy removes an idea" do
    assert_difference 'Idea.count', -1 do
      delete :destroy, id: ideas(:one), format: :json
    end
  end

end
