class SpeakerSerializer < ActiveModel::Serializer
  attributes :name, :bio, :github_account
end
