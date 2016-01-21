class IdeaSerializer < ActiveModel::Serializer
  attributes :id, :title, :body, :quality
end
