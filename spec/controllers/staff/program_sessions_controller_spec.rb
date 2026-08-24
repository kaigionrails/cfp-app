require 'rails_helper'

describe Staff::ProgramSessionsController, type: :controller do

  let(:event) { create(:event) }
  let(:user) do
    create(:user,
           organizer_teammates:
             [ create(:teammate, role: 'organizer', event: event) ],
          )
  end

  before do
    sign_in(user)
  end

  describe '#index' do
    it "downloads live sessions as JSON with the latest speaker bio" do
      program_session = create(:program_session_with_proposal, event: event, state: "live")
      speaker_user = create(:user, bio: "Original bio")
      create(:speaker, user: speaker_user, bio: "Original bio",
             event: event, program_session: program_session)
      speaker_user.update!(bio: "Updated user bio")

      get :index, params: {event_slug: event.slug}, format: :json

      expect(response.status).to eq(200)
      parsed = JSON.parse(response.body)
      expect(parsed.size).to eq(1)
      expect(parsed.first.keys).to match_array(
        %w[title abstract format track tags id video_url slides_url speakers]
      )
      expect(parsed.first["speakers"]).to eq([
        {
          "name" => speaker_user.name,
          "bio" => "Updated user bio",
          "bio_source" => "user",
          "github_account" => nil,
          "gravatar_hash" => User.gravatar_hash(speaker_user.email)
        }
      ])
    end
  end
end
