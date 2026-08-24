require 'rails_helper'

describe Speaker do
  describe "#latest_bio" do
    let(:user) { create(:user, bio: "Original bio") }
    let(:speaker) { create(:speaker, user: user, bio: "Original bio") }

    it "returns the speaker bio when both bios are the same" do
      expect(speaker.latest_bio).to eq("Original bio")
      expect(speaker.latest_bio_source).to eq("speaker")
    end

    it "returns the user bio when the user profile was updated later" do
      speaker
      user.update!(bio: "Updated user bio")

      expect(speaker.latest_bio).to eq("Updated user bio")
      expect(speaker.latest_bio_source).to eq("user")
    end

    it "returns the speaker bio when the speaker was updated later" do
      user.update!(bio: "Updated user bio")
      speaker.update!(bio: "Updated speaker bio")

      expect(speaker.latest_bio).to eq("Updated speaker bio")
      expect(speaker.latest_bio_source).to eq("speaker")
    end

    it "returns the speaker bio when the speaker has no user" do
      speaker = create(:speaker, user: nil, bio: "Orphan bio",
                       speaker_name: "name", speaker_email: "a@example.com")

      expect(speaker.latest_bio).to eq("Orphan bio")
      expect(speaker.latest_bio_source).to eq("speaker")
    end
  end
end
