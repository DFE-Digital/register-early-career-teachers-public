RSpec.describe Schools::ECTs::TeacherLeavingWizard::ConfirmationStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) do
    instance_double(
      Schools::ECTs::TeacherLeavingWizard::Wizard,
      store:,
      ect_at_school_period:,
      author:
    )
  end

  let(:store) do
    FactoryBot.build(:session_repository, form_key: :teacher_leaving_wizard).tap { |repo| repo.leaving_on = store_leaving_on }
  end

  let(:ect_at_school_period) { FactoryBot.build_stubbed(:ect_at_school_period, teacher:, finished_on: Date.new(2024, 12, 31)) }
  let(:teacher) { FactoryBot.build_stubbed(:teacher, corrected_name: "Batman") }
  let(:author) { instance_double(User) }
  let(:store_leaving_on) { { "1" => "2025", "2" => "3", "3" => "1" } }

  before do
    allow(wizard).to receive(:name_for).and_return("Batman")
  end

  describe "#leaving_date" do
    context "when store has a value" do
      it "parses the stored date" do
        expect(step.leaving_date).to eq(Date.new(2025, 3, 1))
      end
    end

    context "when store is blank" do
      let(:store_leaving_on) { nil }

      it "falls back to the ect_at_school_period finished_on" do
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
        expect(step.heading_title).to eq("Batman has been removed from your school’s ECT list")
        expect(step.training_message).to be_nil
        expect(step.notification_message).to eq("We’ll let Batman’s appropriate body and lead provider know (if they’re on a provider-led programme) that you’ve told us that they’ve left your school and are not expected to return. They may contact your school for more information.")
        expect(step.mentor_training_message).to eq("Batman’s mentor can continue their mentor training, even if they do not have other ECTs assigned to them.")
      end
    end

    context "when date is in the future" do
      let(:store_leaving_on) { { "1" => "2025", "2" => "1", "3" => "2" } }

      it "returns the future tense variants" do
        expect(step.leaving_in_future?).to be(true)
        expect(step.heading_title).to eq("Batman will be removed from your school’s ECT list after 2 January 2025")
        expect(step.training_message).to eq("Batman should continue with their current training programme until their leaving date.")
        expect(step.notification_message).to eq("We’ll let their appropriate body and lead provider know (if they’re on a provider-led programme) that you’ve told us that they’re leaving your school and are not expected to return. They may contact your school for more information.")
        expect(step.mentor_training_message).to eq("Batman’s mentor can continue their mentor training, even if they do not have other ECTs assigned to them.")
      end
    end

    context "when date is in the past" do
      let(:store_leaving_on) { { "1" => "2024", "2" => "12", "3" => "31" } }

      it "returns the past tense variants" do
        expect(step.leaving_in_future?).to be(false)
        expect(step.heading_title).to eq("Batman has been removed from your school’s ECT list")
        expect(step.training_message).to be_nil
        expect(step.notification_message).to eq("We’ll let Batman’s appropriate body and lead provider know (if they’re on a provider-led programme) that you’ve told us that they’ve left your school and are not expected to return. They may contact your school for more information.")
        expect(step.mentor_training_message).to eq("Batman’s mentor can continue their mentor training, even if they do not have other ECTs assigned to them.")
      end
    end
  end
end
