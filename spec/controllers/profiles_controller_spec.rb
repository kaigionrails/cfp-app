require 'rails_helper'

describe ProfilesController, type: :controller do
  describe 'GET #edit' do
    let(:user) { create :user }
    let(:action) { :edit }
    let(:params) { {} }

    before { sign_in user }

    context 'user profile is complete' do
      it 'should succeed' do
        get :edit
        expect(response.status).to eq(200)
      end

      it 'does not return a flash warning' do
        get :edit
        expect(flash[:warning]).not_to be_present
      end
    end

    context 'user profile is incomplete' do
      let(:lead_in_msg) { 'Your profile is incomplete. Please correct the following:' }
      let(:trailing_msg) { '.' }

      it_behaves_like 'an incomplete profile notifier'
    end
  end

  describe 'PUT #update' do
    let(:user) { create(:user) }
    let(:params) {
      { user: { bio: 'foo' } }
    }

    before { allow(controller).to receive(:current_user).and_return(user) }

    context 'simple case' do
      it "updates the user record" do
        put :update, params: params
        expect(response.code).to eq("302")
      end
    end

    context "when the user has submitted proposals" do
      let(:event) { create(:event) }
      let(:event2) { create(:event) }
      let(:proposal) { create(:proposal_with_track, event: event) }
      let(:proposal2) { create(:proposal_with_track, event: event2) }
      let(:speaker) {
        create(:speaker, user: user, event: event, speaker_name: "old name", speaker_email: "old@example.invalid", bio: "old bio")
      }
      let(:speaker2) { # current event but not updated speaker
        create(:speaker, event: event, speaker_name: "no effort speaker", speaker_email: "old2@example.invalid", bio: "old bio2")
      }
      let(:speaker3) { # not current event speaker
        create(:speaker, user: user, event: event2, speaker_name: "old name", speaker_email: "old@example.invalid", bio: "old bio")
      }
      let(:params) {
        { user: { bio: "new bio", name: "new name", email: "new@example.invalid" } }
      }

      before do
        allow(controller).to receive(:current_event).and_return(event)
        proposal.speakers << [speaker, speaker2]
        proposal2.speakers << speaker3
      end

      it "update submitted proposal speaker also" do
        put :update, params: params
        expect(response.code).to eq("302")
        expect(proposal.speakers.find_by!(user_id: user.id).bio).to eq("new bio")
        expect(proposal.speakers.first.speaker_email).to eq("new@example.invalid")
        expect(proposal.speakers.first.speaker_name).to eq("new name")
        expect(proposal.speakers.last.speaker_name).to eq("no effort speaker")
        expect(proposal2.speakers.first.bio).to eq("old bio") # did not update not current event proposal speaker
      end
    end
  end
end
