require "rails_helper"

RSpec.describe Staff::SpeakerEmailTemplatesController, type: :controller do
  let(:event) { create(:event) }
  let(:user) do
    create(
      :user,
      organizer_teammates: [create(:teammate, :organizer, event: event)]
    )
  end

  before do
    sign_in(user)
  end

  describe "POST 'deliver'" do
    let(:deliveries) { [] }

    before do
      allow(Staff::ProposalMailer).to receive(:send_email) do |proposal, type:|
        deliveries << [proposal, type]
        double(deliver_later: true)
      end
    end

    it "queues the selected email for proposals in the event with the matching state" do
      accepted = create(:proposal, event: event, state: :accepted)
      create(:proposal, event: event, state: :waitlisted)
      create(:proposal, event: create(:event), state: :accepted)

      post :deliver, params: {event_slug: event.slug, id: "accept"}

      expect(deliveries).to eq([[accepted, :accept]])
      expect(response).to redirect_to(event_staff_speaker_email_templates_path(event))
      expect(flash[:info]).to eq("'Accept' email queued for 1 proposal.")
    end

    it "queues the All email for every proposal in the event" do
      submitted = create(:proposal, event: event, state: :submitted)
      accepted = create(:proposal, event: event, state: :accepted)
      create(:proposal, event: create(:event), state: :submitted)

      post :deliver, params: {event_slug: event.slug, id: "all"}

      expect(deliveries).to contain_exactly([submitted, :all], [accepted, :all])
      expect(flash[:info]).to eq("'All' email queued for 2 proposals.")
    end

    it "does not allow non-organizer staff to queue emails" do
      user.teammates.find_by!(event: event).update!(role: :reviewer)
      create(:proposal, event: event, state: :submitted)

      post :deliver, params: {event_slug: event.slug, id: "all"}

      expect(deliveries).to be_empty
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end
end
