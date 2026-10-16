RSpec.describe "Recording the authentication of an appropriate body user" do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  describe "after authentication" do
    it "creates the DfE Sign In organisation and records the first sign in" do
      expect {
        sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
      }.to change(DfESignInOrganisation, :count).by(1)

      dfe_sign_in_organisation = DfESignInOrganisation.last

      expect(dfe_sign_in_organisation.first_authenticated_at).to be_present
      expect(dfe_sign_in_organisation.last_authenticated_at).to eq(dfe_sign_in_organisation.first_authenticated_at)
      expect(dfe_sign_in_organisation.appropriate_body_period).to eq(appropriate_body_period)
    end

    it "updates the last sign in time on a subsequent sign in" do
      sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
      dfe_sign_in_organisation = DfESignInOrganisation.last
      first_sign_in_at = dfe_sign_in_organisation.last_authenticated_at

      travel 2.hours do
        expect {
          sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)
        }.not_to change(DfESignInOrganisation, :count)

        dfe_sign_in_organisation.reload

        expect(dfe_sign_in_organisation.last_authenticated_at).to be > first_sign_in_at
        expect(dfe_sign_in_organisation.first_authenticated_at).to be < dfe_sign_in_organisation.last_authenticated_at
      end
    end
  end
end
