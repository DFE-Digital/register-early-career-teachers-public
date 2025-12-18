RSpec.describe Schools::Mentors::TeacherLeavingWizard::ConfirmationStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) do
    instance_double(
      Schools::Mentors::TeacherLeavingWizard::Wizard,
      store:,
      mentor_at_school_period:,
      author:
    )
  end

  let(:store) do
    FactoryBot.build(:session_repository, form_key: :teacher_leaving_wizard).tap do |repo|
      repo.leaving_on = store_leaving_on
    end
  end

  let(:teacher) { FactoryBot.build_stubbed(:teacher, corrected_name: "Peter Wright") }
  let(:mentor_at_school_period) do
    FactoryBot.build_stubbed(:mentor_at_school_period, teacher:, finished_on: Date.new(2024, 12, 31))
  end
  let(:author) { instance_double(User) }
  let(:store_leaving_on) { { "1" => "2025", "2" => "3", "3" => "1" } }

  before do
    allow(wizard).to receive(:name_for).and_return("Peter Wright")
  end

  describe "#leaving_date" do
    context "when store has a value" do
      it "parses the stored date" do
        expect(step.leaving_date).to eq(Date.new(2025, 3, 1))
      end
    end

    context "when store is blank" do
      let(:store_leaving_on) { nil }

      it "falls back to the mentor_at_school_period finished_on" do
        expect(step.leaving_date).to eq(Date.new(2024, 12, 31))
      end
    end
  end

  describe "content helpers" do
    around do |example|
      travel_to(Date.new(2025, 1, 1)) { example.run }
    end

    context "when date is today" do
      let(:store_leaving_on) { { "1" => "2025", "2" => "1", "3" => "1" } }

      it "returns the past tense variants" do
        expect(step.leaving_in_future?).to be(false)
        expect(step.heading_title).to eq("Peter Wright has been removed from your school’s mentor list")
        expect(step.assigned_ects_message).to eq("ECTs currently assigned to Peter Wright will need to be reassigned to another mentor.")
        expect(step.training_heading).to be_nil
        expect(step.training_message).to be_nil
        expect(step.notification_message).to eq("We’ll let Peter Wright’s lead provider know (if they were doing a mentor training programme) that you’ve told us that they’ve left your school and are not expected to return. They may contact your school for more information.")
      end
    end

    context "when date is in the future" do
      let(:store_leaving_on) { { "1" => "2025", "2" => "3", "3" => "1" } }

      it "returns the future tense variants" do
        expect(step.leaving_in_future?).to be(true)
        expect(step.heading_title).to eq("Peter Wright will be removed from your school’s mentor list after 1 March 2025")
        expect(step.assigned_ects_message).to eq("ECTs currently assigned to Peter Wright will need to be reassigned to another mentor.")
        expect(step.training_heading).to eq("If Peter Wright is doing mentor training")
        expect(step.training_message).to eq("They should continue with their current training programme until their leaving date.")
        expect(step.notification_message).to eq("We’ll let their lead provider know that you’ve told us that they’re leaving your school and are not expected to return. They may contact your school for more information.")
      end
    end

    context "when date is in the past" do
      let(:store_leaving_on) { { "1" => "2024", "2" => "12", "3" => "31" } }

      it "returns the past tense variants" do
        expect(step.leaving_in_future?).to be(false)
        expect(step.heading_title).to eq("Peter Wright has been removed from your school’s mentor list")
        expect(step.assigned_ects_message).to eq("ECTs currently assigned to Peter Wright will need to be reassigned to another mentor.")
        expect(step.training_heading).to be_nil
        expect(step.training_message).to be_nil
        expect(step.notification_message).to eq("We’ll let Peter Wright’s lead provider know (if they were doing a mentor training programme) that you’ve told us that they’ve left your school and are not expected to return. They may contact your school for more information.")
      end
    end
  end
end
