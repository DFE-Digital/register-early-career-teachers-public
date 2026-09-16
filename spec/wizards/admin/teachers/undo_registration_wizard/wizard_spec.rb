RSpec.describe Admin::Teachers::UndoRegistrationWizard::Wizard do
  let(:store) { FactoryBot.build(:session_repository) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:current_step) { :start }
  let(:wizard) do
    described_class.new(
      store:,
      teacher_id: teacher.id,
      current_step:
    )
  end

  describe ".step?" do
    it "returns true for a configured step" do
      expect(described_class.step?(:start)).to be(true)
    end

    it "returns false for an unknown step" do
      expect(described_class.step?(:unknown)).to be(false)
    end
  end

  describe "#allowed_steps" do
    subject { wizard.allowed_steps }

    context "when the teacher has no at school periods" do
      it { is_expected.to eq([:start]) }
    end

    context "when the teacher has one ECT at school period" do
      before { FactoryBot.create(:ect_at_school_period, teacher:) }

      it { is_expected.to eq(%i[start confirm]) }
    end

    context "when the teacher has one mentor at school period" do
      before { FactoryBot.create(:mentor_at_school_period, teacher:) }

      it { is_expected.to eq(%i[start confirm]) }
    end

    context "when the teacher has multiple ECT at school periods" do
      before do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          started_on: 2.years.ago.to_date,
          finished_on: 1.year.ago.to_date
        )
        FactoryBot.create(:ect_at_school_period, teacher:, started_on: 6.months.ago.to_date, finished_on: nil)
      end

      it { is_expected.to eq([:start]) }
    end

    context "when the teacher has both ECT and mentor at school periods" do
      before do
        FactoryBot.create(:ect_at_school_period, teacher:)
        FactoryBot.create(:mentor_at_school_period, teacher:)
      end

      it { is_expected.to eq([:start]) }
    end

    context "when the registration has been undone" do
      before { store.registration_undone = true }

      it { is_expected.to eq([:confirmation]) }
    end
  end

  describe "#at_school_period" do
    subject { wizard.at_school_period }

    context "when the teacher has one ECT at school period" do
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }

      it { is_expected.to eq(ect_at_school_period) }
    end

    context "when the teacher has one mentor at school period" do
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }

      it { is_expected.to eq(mentor_at_school_period) }
    end

    context "when the teacher has no at school periods" do
      it { is_expected.to be_nil }
    end

    context "when the teacher has multiple at school periods" do
      before do
        FactoryBot.create(:ect_at_school_period, teacher:)
        FactoryBot.create(:mentor_at_school_period, teacher:)
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#teacher_name" do
    it "returns the teachers full name" do
      expect(wizard.teacher_name).to eq(::Teachers::Name.new(teacher).full_name)
    end
  end

  describe "step paths" do
    let(:url_helpers) { Rails.application.routes.url_helpers }

    it "returns the current step path" do
      expect(wizard.current_step_path)
        .to eq(url_helpers.admin_teacher_undo_registration_wizard_start_path(teacher))
    end

    it "returns the next step path" do
      expect(wizard.next_step_path)
        .to eq(url_helpers.admin_teacher_undo_registration_wizard_confirm_path(teacher))
    end

    context "on the confirm step" do
      let(:current_step) { :confirm }

      it "returns the previous step path" do
        expect(wizard.previous_step_path)
          .to eq(url_helpers.admin_teacher_undo_registration_wizard_start_path(teacher))
      end
    end
  end
end
