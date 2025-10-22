RSpec.shared_examples "an API teacher shared action", :with_metadata do
  let(:lead_provider) { training_period.lead_provider }
  let(:lead_provider_id) { lead_provider.id }
  let(:teacher) { training_period.trainee.teacher }
  let(:teacher_api_id) { teacher.api_id }

  describe "validations" do
    subject { instance }

    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 2.months.ago) }
        let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }
        let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

        it { is_expected.to be_valid }
        it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Enter a '#/lead_provider_id'.") }
        it { is_expected.to validate_presence_of(:teacher_api_id).with_message("Enter a '#/teacher_api_id'.") }
        it { is_expected.to validate_inclusion_of(:course_identifier).in_array(%w[ecf-induction ecf-mentor]).with_message("The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.") }

        context "when the `lead_provider` does not exist" do
          let(:lead_provider_id) { 9999 }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.") }
        end

        context "when a matching training period does not exist (different course identifier)" do
          let(:course_identifier) { trainee_type == :ect ? "ecf-mentor" : "ecf-induction" }

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
  end
end
