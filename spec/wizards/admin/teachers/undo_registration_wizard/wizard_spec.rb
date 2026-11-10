RSpec.describe Admin::Teachers::UndoRegistrationWizard::Wizard do
  subject(:wizard) { described_class.new(state_store:, current_step:) }

  let(:state_store) do
    Admin::Teachers::UndoRegistrationWizard::StateStore.new(teacher:, author: instance_double(User))
  end
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:current_step) { :start }
  let!(:at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher:) }

  def path_for(step)
    Rails.application.routes.url_helpers.public_send(
      "admin_teacher_undo_registration_wizard_#{step}_path", teacher
    )
  end

  it { is_expected.to have_root_step(:start) }

  it "defines a route for every step" do
    expect(described_class.routes).to match_array(wizard.step_definitions.keys)
  end

  it "resolves step paths for the teacher" do
    expect(wizard).to resolve_step(:confirm).to(path_for(:confirm))
  end

  describe "operations" do
    it "runs validation followed by the undo operation" do
      expect(wizard).to have_step_operations(
        confirm: [DfE::Wizard::Operations::Validate, Admin::Teachers::UndoRegistrationWizard::Operations::UndoRegistration]
      )
    end
  end

  describe "navigation" do
    it { is_expected.to have_next_step(:confirm).from(:start) }
    it { is_expected.to have_previous_step(:start).from(:confirm) }
    it { is_expected.to have_next_step(:confirmation).from(:confirm) }

    context "when the teacher has multiple school periods" do
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:) }

      it { is_expected.to have_next_step(:select_school_period).from(:start) }
      it { is_expected.to have_next_step(:confirm).from(:select_school_period) }
      it { is_expected.to have_previous_step(:start).from(:select_school_period) }
      it { is_expected.to have_previous_step(:select_school_period).from(:confirm) }
    end
  end

  describe "#valid_path_to_current_step?" do
    it "allows the confirm form when the teacher has one school period" do
      wizard.current_step_name = :confirm

      expect(wizard).to be_valid_path_to_current_step
    end

    it "blocks the success page when the confirm form has not been completed" do
      wizard.current_step_name = :confirmation

      expect(wizard).not_to be_valid_path_to_current_step
    end

    context "when the teacher has multiple school periods" do
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:) }
      let(:current_step) { :confirm }

      it "requires a selection" do
        expect(wizard).not_to be_valid_path_to_current_step
      end

      it "allows the confirm form after a valid school period is selected" do
        state_store.write(at_school_period_gid: mentor_at_school_period.to_global_id.to_s)

        expect(wizard).to be_valid_path_to_current_step
      end

      it "rejects a selection belonging to another teacher" do
        other_school_period = FactoryBot.create(:ect_at_school_period)
        state_store.write(at_school_period_gid: other_school_period.to_global_id.to_s)

        expect(wizard).not_to be_valid_path_to_current_step
      end
    end

    context "when the teacher has one school period but visits the selection step" do
      let(:current_step) { :select_school_period }

      it "does not allow access" do
        expect(wizard).not_to be_valid_path_to_current_step
      end
    end
  end

  describe "#furthest_valid_step_path" do
    subject { wizard.furthest_valid_step_path }

    it { is_expected.to eq(path_for(:confirm)) }

    context "when the teacher has multiple school periods" do
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:) }

      it { is_expected.to eq(path_for(:select_school_period)) }

      context "when the teacher has selected one of multiple school periods" do
        before { state_store.write(at_school_period_gid: mentor_at_school_period.to_global_id.to_s) }

        it { is_expected.to eq(path_for(:confirm)) }
      end

      context "when the selected school period belongs to another teacher" do
        before do
          other_school_period = FactoryBot.create(:ect_at_school_period)
          state_store.write(at_school_period_gid: other_school_period.to_global_id.to_s)
        end

        it { is_expected.to eq(path_for(:select_school_period)) }
      end
    end
  end
end
