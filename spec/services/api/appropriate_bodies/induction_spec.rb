RSpec.describe API::AppropriateBodies::Induction do
  subject(:induction) { described_class.new(appropriate_body:, client:) }

  include_context "test TRS API returns a teacher"

  let(:appropriate_body) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:client) { FactoryBot.create(:api_oauth_client) }
  let(:started_on) { 1.month.ago.to_date }
  let(:claim_params) { { trn: "1234567", date_of_birth: "2001-05-13", started_on:, training_programme: "school_led" } }

  describe "#claim!" do
    it "registers the ECT with the appropriate body and returns the claim" do
      claim = induction.claim!(**claim_params)

      expect(claim.symbolize_keys).to eq(trn: "1234567", full_name: "Kirk Van Houten", started_on:, training_programme: "school_led")
      expect(Teacher.find_by!(trn: "1234567").ongoing_induction_period.appropriate_body_period).to eq(appropriate_body)
    end

    it "raises a validation error when the claim is invalid" do
      expect { induction.claim!(**claim_params, date_of_birth: nil) }
        .to raise_error(described_class::Invalid, /Enter a date of birth/)
    end
  end
end
