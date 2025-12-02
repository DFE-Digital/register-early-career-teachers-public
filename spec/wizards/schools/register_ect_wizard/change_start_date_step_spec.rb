RSpec.describe Schools::RegisterECTWizard::ChangeStartDateStep, type: :model do
  subject(:step) { described_class.new(wizard:, start_date: new_start_date) }

  let(:new_start_date) { "1 July 2024" }

  let(:school) { FactoryBot.create(:school, :state_funded) }

  let(:store) do
    FactoryBot.build(
      :session_repository,
      start_date: "3 September 2024",
      use_previous_ect_choices: true
    )
  end

  let(:wizard) do
    FactoryBot.build(
      :register_ect_wizard,
      current_step: :change_start_date,
      store:,
      school:
    )
  end

  before do
    store[:school_partnership_to_reuse_id] = 123
  end

  describe "#save!" do
    it "updates the wizard ect start date" do
      expect { step.save! }
        .to change(step.ect, :start_date)
        .to("1 July 2024")
    end

    it "resets use_previous_ect_choices on the ect" do
      expect { step.save! }
        .to change(step.ect, :use_previous_ect_choices)
        .to(nil)
    end

    it "clears stored school_partnership_to_reuse_id" do
      step.save!
      expect(store[:school_partnership_to_reuse_id]).to be_nil
    end
  end
end
