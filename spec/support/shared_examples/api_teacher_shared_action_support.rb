RSpec.shared_examples "an API teacher shared action", :with_metadata do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:lead_provider) { active_lead_provider.lead_provider }
  let(:lead_provider_delivery_partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider:
    )
  end
  let(:school_partnership) do
    FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:)
  end
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      school: school_partnership.school,
      started_on: 1.year.ago,
      finished_on: nil
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :with_school_partnership,
      school_partnership:,
      ect_at_school_period:,
      started_on: ect_at_school_period.started_on + 1.week,
      finished_on: nil
    )
  end
  let(:teacher) { ect_at_school_period.teacher }
  let(:lead_provider_id) { lead_provider.id }
  let(:teacher_api_id) { teacher.api_id }
  let(:course_identifier) { "ecf-induction" }

  it { expect(instance).to be_valid }

  describe "validations" do
    subject { instance }

    it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Enter a '#/lead_provider_id'.") }
    it { is_expected.to validate_presence_of(:teacher_api_id).with_message("Enter a '#/teacher_api_id'.") }
    it { is_expected.to validate_inclusion_of(:course_identifier).in_array(%w[ecf-induction ecf-mentor]).with_message("The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }

    context "when a matching training period does not exist (different course identifier)" do
      let(:course_identifier) { "ecf-mentor" }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.") }
    end

    context "when a matching training period does not exist (different lead provider)" do
      let(:lead_provider_id) { FactoryBot.create(:lead_provider, name: "Different to #{lead_provider.name}").id }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.") }
    end

    context "when the teacher does not exist" do
      let(:teacher_api_id) { "non-existent-participant-id" }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.") }
    end

    context "when a non-existent course identifier is provided" do
      let(:course_identifier) { "non-existent-course-identifier" }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_error(:course_identifier, "The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }
    end

    context "when an empty course identifier is provided" do
      let(:course_identifier) { "" }

      it { is_expected.to have_error(:course_identifier, "Enter a '#/course_identifier'.") }
    end

    context "when a nil course identifier is provided" do
      let(:course_identifier) { nil }

      it { is_expected.to have_error(:course_identifier, "Enter a '#/course_identifier'.") }
    end
  end
end
