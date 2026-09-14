RSpec.describe Schools::ECTs::ChangeStartDateWizard::CannotUseDateStep do
  subject(:current_step) do
    described_class.new(wizard:)
  end

  let(:wizard) do
    instance_double(
      Schools::ECTs::ChangeStartDateWizard::Wizard,
      store:
    )
  end

  let(:store) do
    FactoryBot.build(
      :session_repository,
      form_key: :change_start_date_wizard
    )
  end

  before do
    store.start_date = {
      "1" => "2026",
      "2" => "9",
      "3" => "1"
    }
  end

  describe "#previous_step" do
    it "returns edit" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#start_date" do
    it "returns the selected start date" do
      expect(current_step.start_date)
        .to eq(Date.new(2026, 9, 1))
    end
  end
end
