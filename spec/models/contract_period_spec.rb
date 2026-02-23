describe ContractPeriod do
  describe "associations" do
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:schedules).inverse_of(:contract_period) }
    it { is_expected.to have_many(:active_lead_providers).inverse_of(:contract_period) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).through(:active_lead_providers) }
  end

  describe "validations" do
    subject { FactoryBot.build(:contract_period) }

    it { is_expected.to validate_presence_of(:year) }
    it { is_expected.to validate_uniqueness_of(:year) }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than_or_equal_to(2020) }

    it { is_expected.to validate_presence_of(:started_on).with_message("Enter a start date") }
    it { is_expected.to validate_presence_of(:finished_on).with_message("Enter an end date") }

    %i[mentor_funding_enabled detailed_evidence_types_enabled uplift_fees_enabled].each do |attribute|
      it { is_expected.to allow_values(true, false).for(attribute) }
      it { is_expected.not_to allow_values(nil, "").for(attribute) }
    end

    describe "#no_overlaps" do
      before { FactoryBot.create(:contract_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 2, 2)) }

      it "allows new records that do not overlap" do
        non_overlapping = FactoryBot.build(:contract_period, started_on: Date.new(2024, 2, 2), finished_on: Date.new(2024, 3, 3))
        expect(non_overlapping).to be_valid
      end

      it "does not allow overlapping records" do
        overlapping = FactoryBot.build(:contract_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 3, 3))
        expect(overlapping).not_to be_valid
        expect(overlapping.errors.messages[:base]).to include(/Contract period overlaps/)
      end
    end
  end

  describe ".containing_date" do
    let!(:period) do
      FactoryBot.create(:contract_period, started_on: Date.new(2024, 9, 1), finished_on: Date.new(2025, 8, 31))
    end

    it "returns the contract_period containing the given date" do
      expect(ContractPeriod.containing_date(Date.new(2025, 1, 1))).to eq(period)
    end

    it "returns nil when no period contains the date" do
      expect(ContractPeriod.containing_date(Date.new(2023, 1, 1))).to be_nil
    end
  end

  describe ".current" do
    context "when there is a current contract period" do
      let!(:period) do
        FactoryBot.create(:contract_period, started_on: Date.new(2024, 6, 1), finished_on: Date.new(2025, 5, 31))
      end

      it "returns the current contract period" do
        FactoryBot.create(:contract_period, started_on: Date.new(2023, 6, 1), finished_on: Date.new(2024, 5, 31))

        travel_to Date.new(2024, 6, 1) do
          expect(ContractPeriod.current).to eq(period)
        end
      end
    end

    context "when there is no current contract period" do
      it "returns nil" do
        travel_to Date.new(2025, 6, 1) do
          expect(ContractPeriod.current).to be_nil
        end
      end
    end
  end

  describe ".earliest_permitted_start_date" do
    context "when there are contract periods" do
      let!(:oldest) do
        FactoryBot.create(:contract_period, year: 2022)
      end

      let!(:third_oldest) do
        FactoryBot.create(:contract_period, year: 2023)
      end

      let!(:second_oldest) do
        FactoryBot.create(:contract_period, year: 2024)
      end

      let!(:current) do
        FactoryBot.create(:contract_period, year: 2025)
      end

      it "returns the start date of the contract period two periods before the current one" do
        freeze_time do
          expect(ContractPeriod.earliest_permitted_start_date).to eq(third_oldest.started_on)
        end
      end
    end

    context "when there are no current contract periods" do
      it "returns nil" do
        freeze_time do
          expect(ContractPeriod.earliest_permitted_start_date).to be_nil
          expect(ContractPeriod.count).to eq(0)
        end
      end
    end
  end

  describe "check constraints" do
    subject { FactoryBot.build(:contract_period, started_on: Date.current, finished_on: Date.current) }

    it "prevents 0 day periods from being written to the database" do
      expect { subject.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    end
  end

  describe "scopes" do
    describe ".most_recent_first" do
      let!(:period_2022) { FactoryBot.create(:contract_period, year: 2022, started_on: Date.new(2022, 6, 1), finished_on: Date.new(2023, 5, 31)) }
      let!(:period_2024) { FactoryBot.create(:contract_period, year: 2024, started_on: Date.new(2024, 6, 1), finished_on: Date.new(2025, 5, 31)) }
      let!(:period_2023) { FactoryBot.create(:contract_period, year: 2023, started_on: Date.new(2023, 6, 1), finished_on: Date.new(2024, 5, 31)) }
      let!(:period_2025) { FactoryBot.create(:contract_period, year: 2025, started_on: Date.new(2025, 6, 1), finished_on: Date.new(2026, 5, 31)) }

      it "orders contract periods by year in descending order" do
        result = ContractPeriod.most_recent_first
        expect(result.to_a).to eq([period_2025, period_2024, period_2023, period_2022])
      end

      it "returns contract periods with most recent year first" do
        result = ContractPeriod.most_recent_first
        expect(result.first).to eq(period_2025)
        expect(result.last).to eq(period_2022)
      end
    end

    describe ".enabled" do
      subject { described_class.enabled }

      let!(:enabled_period) { FactoryBot.create(:contract_period, enabled: true) }

      before { FactoryBot.create(:contract_period, enabled: false) }

      it { is_expected.to contain_exactly(enabled_period) }
    end
  end

  describe "#started_on_or_before_today?" do
    let(:today) { Time.zone.today }

    context "when contract period started in the past" do
      let(:contract_period) { FactoryBot.create(:contract_period, started_on: 1.month.ago, finished_on: 1.month.from_now) }

      it "returns true" do
        expect(contract_period.started_on_or_before_today?).to be true
      end
    end

    context "when contract period starts today" do
      let(:contract_period) { FactoryBot.create(:contract_period, started_on: today, finished_on: 1.month.from_now) }

      it "returns true" do
        expect(contract_period.started_on_or_before_today?).to be true
      end
    end

    context "when contract period starts in the future" do
      let(:contract_period) { FactoryBot.create(:contract_period, started_on: 1.month.from_now, finished_on: 2.months.from_now) }

      it "returns false" do
        expect(contract_period.started_on_or_before_today?).to be false
      end
    end
  end

  describe "#payments_frozen?" do
    subject { FactoryBot.build(:contract_period, payments_frozen_at:) }

    context "when `payments_frozen_at` is nil" do
      let(:payments_frozen_at) { nil }

      it { is_expected.not_to be_payments_frozen }
    end

    context "when `payments_frozen_at` is in the future" do
      let(:payments_frozen_at) { 1.day.from_now }

      it { is_expected.not_to be_payments_frozen }
    end

    context "when `payments_frozen_at` is in the past" do
      let(:payments_frozen_at) { 1.day.ago }

      it { is_expected.to be_payments_frozen }
    end

    context "when `payments_frozen_at` is now" do
      let(:payments_frozen_at) { Time.zone.now }

      before { freeze_time }

      it { is_expected.to be_payments_frozen }
    end
  end
end
