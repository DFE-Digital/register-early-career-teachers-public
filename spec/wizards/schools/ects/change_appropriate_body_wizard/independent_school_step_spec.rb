require_relative "./shared_examples/appropriate_body_step"

describe Schools::ECTs::ChangeAppropriateBodyWizard::IndependentSchoolStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeAppropriateBodyWizard::Wizard.new(
      current_step: :independent_school,
      step_params: ActionController::Parameters.new(independent_school: params),
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
    it "returns the permitted parameters" do
      expect(described_class.permitted_params).to contain_exactly(:appropriate_body_id, :appropriate_body_type)
    end
  end

  describe "#appropriate_body_id" do
    context "when the type is national" do
      let(:params) { { appropriate_body_id: appropriate_body_period.id.to_s, appropriate_body_type: } }
      let(:appropriate_body_type) { "national" }
      let!(:istip) { FactoryBot.create(:appropriate_body_period, :istip) }

      it "populate the instance from ISTIP" do
        expect(subject.appropriate_body_id).to eq(istip.id.to_s)
      end
    end

    context "when the type is not national" do
      let(:params) { { appropriate_body_id: appropriate_body_period.id.to_s, appropriate_body_type: } }
      let(:appropriate_body_type) { "teaching_hub" }

      it "populate the instance from the arguments" do
        expect(subject.appropriate_body_id).to eq(appropriate_body_period.id.to_s)
      end
    end

    context "when the type is not provided" do
      let(:params) { { appropriate_body_id: appropriate_body_period.id.to_s } }

      it "populate the instance from the arguments" do
        expect(subject.appropriate_body_id).to eq(appropriate_body_period.id.to_s)
      end
    end
  end
end
