class SpeakerSerializer < ActiveModel::Serializer
  attributes :name, :bio, :bio_source, :github_account, :gravatar_hash

  # The bio snapshot on Speaker can fall behind the user profile, so expose
  # whichever is newer along with which side was adopted.
  def bio
    object.latest_bio
  end

  def bio_source
    object.latest_bio_source
  end
end
