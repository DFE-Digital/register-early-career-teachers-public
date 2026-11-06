RSpec.describe Admin::Teachers::UndoRegistrationWizard::Steps::SelectSchoolPeriodStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Admin::Teachers::UndoRegistrationWizard::Wizard.new(
      state_store:,
      current_step: :select_school_period,
      current_step_params:
    )
  end
  let(:state_store) do
    Admin::Teachers::UndoRegistrationWizard::StateStore.new(teacher:, author: instance_double(User))
  end
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Kakashi", trs_last_name: "Hatake") }
  let!(:at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher:) }
  let(:at_school_period_gid) { at_school_period.to_global_id.to_s }
  let(:current_step_params) do
    ActionController::Parameters.new(select_school_period: { at_school_period_gid: })
  end

  describe "validations" do
    context "when a school period has not been selected" do
      let(:at_school_period_gid) { nil }

      it "adds the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:at_school_period_gid])
          .to contain_exactly("Select a school period to undo for Kakashi Hatake")
      end
    end

    context "when a valid school period has been selected" do
      it { is_expected.to be_valid }
    end
  end

  describe "saving" do
    it "stores the selected school period" do
      expect(wizard.save_current_step).to be(true)
      expect(state_store[:at_school_period_gid]).to eq(at_school_period_gid)
    end

    context "when the school period belongs to another teacher" do
      let(:other_teacher) { FactoryBot.create(:teacher) }
      let(:other_teacher_at_school_period) do
        FactoryBot.create(:ect_at_school_period, teacher: other_teacher)
      end
      let(:at_school_period_gid) { other_teacher_at_school_period.to_global_id.to_s }

      it "rejects the submitted period and keeps the previous selection" do
        saved_school_period_gid = at_school_period.to_global_id.to_s
        state_store.write(at_school_period_gid: saved_school_period_gid)

        expect(wizard.save_current_step).to be(false)
        expect(state_store[:at_school_period_gid]).to eq(saved_school_period_gid)
      end
    end
  end
end
