class Api::V1::IdeasController < ApplicationController
  respond_to :json

  def index
    respond_with Idea.order(created_at: :asc)
  end

  def show
    respond_with Idea.find(params[:id])
  end

  def create
    idea = Idea.new(idea_params)
    if idea.save
      respond_with(idea, status: 201, location: api_v1_idea_path(idea))
    else
      render json: { errors: idea.errors }, status: 422, location: api_v1_ideas_path
    end
  end

  def update
    idea = Idea.find(params[:id])
    if idea.update(idea_params)
      respond_with(idea, status: 200, location: api_v1_idea_path(idea))
    else
      render json: idea.errors, status: 422
    end
  end

  def destroy
    Idea.find(params[:id]).destroy
    head :no_content
  end

  private

  def idea_params
    params.require(:idea).permit(:body, :title, :quality)
  end

end
