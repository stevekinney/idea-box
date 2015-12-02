class Api::V1::IdeasController < ApplicationController
  respond_to :json

  def index
    respond_with Idea.all
  end

  def show
    respond_with Idea.find(params[:id])
  end

  def create
    idea = Idea.new(idea_params)
    if idea.save
      respond_with({ idea: idea }, status: 201, location: api_v1_idea_path(idea))
    else
      respond_with({ errors: idea.errors }, status: 422, location: api_v1_ideas_path)
    end
  end

  private

  def idea_params
    params.require(:idea).permit(:body, :title)
  end

end
