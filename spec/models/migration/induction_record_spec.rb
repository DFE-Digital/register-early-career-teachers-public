describe Migration::InductionRecord, type: :model do
  describe "associations" do
    it { is_expected.to have_one(:school_cohort).through(:induction_programme) }
    it { is_expected.to have_one(:school).through(:school_cohort) }
    it { is_expected.to have_one(:partnership).through(:induction_programme) }
    it { is_expected.to have_one(:delivery_partner).through(:partnership) }
    it { is_expected.to have_one(:lead_provider).through(:partnership) }
  end

  describe "#completed?" do
    subject { record.completed? }

    let(:record) { FactoryBot.build(:migration_induction_record, induction_status:) }

    context 'when induction_status is "completed"' do
      let(:induction_status) { "completed" }

      it { is_expected.to be true }
    end

    context 'when induction_status not "completed"' do
      let(:induction_status) { "active" }

      it { is_expected.to be false }
    end
  end

  describe "#leaving?" do
    subject { record.leaving? }

    let(:record) { FactoryBot.build(:migration_induction_record, induction_status:) }

    context 'when induction_status is "leaving"' do
      let(:induction_status) { "leaving" }

      it { is_expected.to be true }
    end

    context 'when induction_status is "active"' do
      let(:induction_status) { "active" }

      it { is_expected.to be false }
    end
  end

  describe "#flipped_dates?" do
    subject { record.flipped_dates? }

    let(:start_date) { Date.new(2025, 1, 10) }
    let(:record) { FactoryBot.build(:migration_induction_record, start_date:, end_date:) }

    context "when end_date is before start_date" do
      let(:end_date) { start_date - 1.day }

      it { is_expected.to be true }
    end

    context "when end_date equals start_date" do
      let(:end_date) { start_date }

      it { is_expected.to be false }
    end

    context "when end_date is after start_date" do
      let(:end_date) { start_date + 1.day }

      it { is_expected.to be false }
    end

    context "when end_date is nil" do
      let(:end_date) { nil }

      it { is_expected.to be false }
    end
  end
end
