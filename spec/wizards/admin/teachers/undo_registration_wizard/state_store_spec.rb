RSpec.describe Admin::Teachers::UndoRegistrationWizard::StateStore do
  subject(:state_store) { described_class.new(teacher:, author:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { instance_double(User) }

  describe "#journey_available?" do
    subject { state_store.journey_available? }

    let(:registration_undoable) { true }
    let(:undo_registration) do
      instance_double(::Teachers::UndoRegistration, undoable?: registration_undoable)
    end

    before do
      allow(::Teachers::UndoRegistration).to receive(:new).and_return(undo_registration)
    end

    context "when the teacher has no at school periods" do
      it { is_expected.to be(false) }
    end

    context "when the teacher has one ECT at school period" do
      before { FactoryBot.create(:ect_at_school_period, teacher:) }

      it { is_expected.to be(true) }
    end

    context "when the teacher has one mentor at school period" do
      before { FactoryBot.create(:mentor_at_school_period, teacher:) }

      it { is_expected.to be(true) }
    end

    context "when the service reports that the registration cannot be undone" do
      let!(:at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
      let(:registration_undoable) { false }

      it { is_expected.to be(false) }

      context "when the teacher has another school period" do
        before do
          FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:)
          state_store.write(at_school_period_gid: at_school_period.to_global_id.to_s)
        end

        it { is_expected.to be(false) }
      end
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

      it { is_expected.to be(true) }
    end

    context "when the teacher has multiple mentor at school periods" do
      before do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          started_on: 2.years.ago.to_date,
          finished_on: 1.year.ago.to_date
        )
        FactoryBot.create(:mentor_at_school_period, teacher:, started_on: 6.months.ago.to_date, finished_on: nil)
      end

      it { is_expected.to be(true) }
    end

    context "when the teacher has both ECT and mentor at school periods" do
      before do
        FactoryBot.create(:ect_at_school_period, teacher:)
        FactoryBot.create(:mentor_at_school_period, teacher:)
      end

      it "allows the user to select a school period before checking undo eligibility" do
        expect(::Teachers::UndoRegistration).not_to receive(:new)

        expect(state_store.journey_available?).to be(true)
      end
    end

    context "when the teacher has selected one of multiple school periods" do
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }

      before do
        FactoryBot.create(:mentor_at_school_period, teacher:)
        state_store.write(at_school_period_gid: ect_at_school_period.to_global_id.to_s)
      end

      it "checks whether the selected registration can be undone" do
        expect(state_store.journey_available?).to be(true)

        expect(::Teachers::UndoRegistration).to have_received(:new).with(
          author:,
          at_school_period: ect_at_school_period,
          reason: :registered_in_error
        )
      end
    end
  end

  describe "#registration_undone?" do
    subject { state_store.registration_undone? }

    it { is_expected.to be(false) }

    context "when the registration has been undone" do
      before { state_store.write(registration_undone: true) }

      it { is_expected.to be(true) }
    end
  end

  describe "#at_school_period" do
    subject { state_store.at_school_period }

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

    context "when the teacher has multiple at school periods and one has been selected" do
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }

      before do
        FactoryBot.create(:ect_at_school_period, teacher:)
        state_store.write(at_school_period_gid: mentor_at_school_period.to_global_id.to_s)
      end

      it { is_expected.to eq(mentor_at_school_period) }
    end

    context "when the selected school period belongs to another teacher" do
      let!(:other_school_period) { FactoryBot.create(:ect_at_school_period) }

      before do
        FactoryBot.create(:ect_at_school_period, teacher:)
        FactoryBot.create(:mentor_at_school_period, teacher:)
        state_store.write(at_school_period_gid: other_school_period.to_global_id.to_s)
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#at_school_periods" do
    let!(:older_ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2023, 9, 1))
    end
    let!(:newer_ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2024, 9, 1))
    end
    let!(:older_mentor_at_school_period) do
      FactoryBot.create(:mentor_at_school_period, teacher:, started_on: Date.new(2023, 9, 1))
    end
    let!(:newer_mentor_at_school_period) do
      FactoryBot.create(:mentor_at_school_period, teacher:, started_on: Date.new(2024, 9, 1))
    end

    it "returns school periods by type and most recent start date" do
      expect(state_store.at_school_periods).to eq(
        [
          newer_ect_at_school_period,
          older_ect_at_school_period,
          newer_mentor_at_school_period,
          older_mentor_at_school_period
        ]
      )
    end
  end

  describe "#teacher_name" do
    it "returns the teachers full name" do
      expect(state_store.teacher_name).to eq(::Teachers::Name.new(teacher).full_name)
    end
  end

  describe "#undo_registration!" do
    let!(:at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
    let(:undo_registration) { instance_double(::Teachers::UndoRegistration) }

    before do
      allow(::Teachers::UndoRegistration).to receive(:new).with(
        author:,
        at_school_period:,
        reason: :registered_in_error
      ).and_return(undo_registration)
    end

    it "undoes the registration for the selected school period" do
      expect(undo_registration).to receive(:undo!).with(
        expected_action: "close",
        expected_training_period_ids: [1],
        expected_mentorship_period_ids: [2],
        expected_at_school_period_gid: at_school_period.to_global_id.to_s
      )

      state_store.undo_registration!(
        expected_action: "close",
        expected_training_period_ids: [1],
        expected_mentorship_period_ids: [2],
        expected_at_school_period_gid: at_school_period.to_global_id.to_s
      )
    end
  end

  describe "#affected_training_periods" do
    let!(:at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher:) }
    let!(:finished_training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period: at_school_period,
        started_on: 10.months.ago.to_date,
        finished_on: 8.months.ago.to_date
      )
    end
    let!(:unfinished_training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :unfinished,
        ect_at_school_period: at_school_period,
        started_on: 6.months.ago.to_date
      )
    end

    context "when the periods will be closed" do
      before do
        FactoryBot.create(:declaration, :eligible, training_period: unfinished_training_period)
      end

      it "includes only unfinished periods" do
        expect(state_store.affected_training_periods).to contain_exactly(unfinished_training_period)
      end
    end

    context "when the periods will be deleted" do
      it "includes every associated period" do
        expect(state_store.affected_training_periods).to contain_exactly(finished_training_period, unfinished_training_period)
      end

      it "preloads associations used by the training period summary" do
        training_period = state_store.affected_training_periods.first

        %i[
          schedule
          school_partnership
          lead_provider
          delivery_partner
          contract_period
          expression_of_interest_lead_provider
          expression_of_interest_contract_period
        ].each do |association|
          expect(training_period.association(association)).to be_loaded
        end
      end
    end
  end
end
