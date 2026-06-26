require_relative "./shared_examples/appropriate_body_step"

describe Schools::ECTs::ChangeAppropriateBodyWizard::StateSchoolStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeAppropriateBodyWizard::Wizard.new(
      current_step: :state_school,
      step_params: ActionController::Parameters.new(state_school: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end

  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, school_reported_appropriate_body:) }
  let(:params) { { appropriate_body_id: appropriate_body_period.id.to_s } }
  let(:school_reported_appropriate_body) { FactoryBot.create(:appropriate_body_period) }
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  it_behaves_like "a change appropriate body step"

  describe ".permitted_params" do
    it "permits the appropriate body ID" do
      expect(described_class.permitted_params).to contain_exactly(:appropriate_body_id)
    end
  end
end
