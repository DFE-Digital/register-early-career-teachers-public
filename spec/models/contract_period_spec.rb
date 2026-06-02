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
        non_overlapping = FactoryBot.build(:contract_period, started_on: Date.new(2024, 2, 3), finished_on: Date.new(2024, 3, 3))
        expect(non_overlapping).to be_valid
      end

      it "does not allow overlapping records" do
        overlapping = FactoryBot.build(:contract_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 3, 3))
        expect(overlapping).not_to be_valid
        expect(overlapping.errors.messages[:started_on]).to include(/Start date cannot overlap another Contract period/)
      end
    end
  end

  # aka containing_date_end_inclusive
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

    context "when the date is on the boundary of a period" do
      it "includes the start date in the period" do
        expect(ContractPeriod.containing_date(Date.new(2024, 9, 1))).to eq(period)
      end

      it "includes the end date in the period" do
        expect(ContractPeriod.containing_date(Date.new(2025, 8, 31))).to eq(period)
      end
    end
  end

  describe ".current" do
    subject(:current) { described_class.current }

    let(:current_contract_period) do
      FactoryBot.create(:contract_period, :current)
    end

    context "when we are in the current contract period" do
      before { travel_to current_contract_period.started_on }

      it { is_expected.to eq(current_contract_period) }
    end

    context "when we are on the last day of the current contract period" do
      before { travel_to current_contract_period.finished_on }

      it { is_expected.to eq(current_contract_period) }
    end

    context "when we are before the current contract period" do
      before { travel_to current_contract_period.started_on.prev_day }

      it { is_expected.to be_nil }
    end

    context "when we are past the current contract period" do
      before { travel_to current_contract_period.finished_on.next_day }

      it { is_expected.to be_nil }
    end
  end

  describe ".upcoming" do
    subject(:upcoming) { described_class.upcoming }

    context "when there are no contract periods" do
      it { is_expected.to be_nil }
    end

    context "when there is only an upcoming contract period" do
      let!(:upcoming_contract_period) do
        FactoryBot.create(:contract_period, :next)
      end

      it { is_expected.to eq(upcoming_contract_period) }
    end

    context "when there is only a current contract period" do
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current)
      end

      it { is_expected.to be_nil }
    end

    context "when there are current and upcoming contract periods" do
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current)
      end
      let!(:upcoming_contract_period) do
        FactoryBot.create(:contract_period, :next)
      end

      it { is_expected.to eq(upcoming_contract_period) }
    end

    context "when there is a closer previous contract period" do
      let!(:previous_contract_period) do
        FactoryBot.create(:contract_period, :previous)
      end
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current)
      end
      let!(:upcoming_contract_period) do
        FactoryBot.create(:contract_period, :next)
      end

      before { travel_to current_contract_period.started_on }

      it { is_expected.to eq(upcoming_contract_period) }
    end
  end

  describe ".current_or_upcoming" do
    subject(:current_or_upcoming) { described_class.current_or_upcoming }

    context "when there are no contract periods" do
      it { is_expected.to be_nil }
    end

    context "when there is only an upcoming contract period" do
      let!(:upcoming_contract_period) do
        FactoryBot.create(:contract_period, :next)
      end

      it { is_expected.to eq(upcoming_contract_period) }
    end

    context "when there is only a current contract period" do
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current)
      end

      it { is_expected.to eq(current_contract_period) }
    end

    context "when there are current and upcoming contract periods" do
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current)
      end
      let!(:upcoming_contract_period) do
        FactoryBot.create(:contract_period, :next)
      end

      it { is_expected.to eq(current_contract_period) }
    end
  end

  describe ".current_or_upcoming!" do
    subject(:current_or_upcoming) { ContractPeriod.current_or_upcoming! }

    context "when there are no contract periods" do
      it "raises an error" do
        expect { current_or_upcoming }.to raise_error("No current or upcoming contract period")
      end
    end

    context "when there is only an upcoming contract period" do
      let!(:upcoming_contract_period) do
        FactoryBot.create(:contract_period, :next)
      end

      it { is_expected.to eq(upcoming_contract_period) }
    end

    context "when there is only a current contract period" do
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current)
      end

      it { is_expected.to eq(current_contract_period) }
    end

    context "when there are current and upcoming contract periods" do
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current)
      end

      let!(:upcoming_contract_period) do
        FactoryBot.create(:contract_period, :next)
      end

      it { is_expected.to eq(current_contract_period) }
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

      context "during the current contract period" do
        around do |example|
          travel_to(Date.new(2025, 9, 1)) do
            example.run
          end
        end

        it "returns the start date of the contract period two periods before the current one" do
          expect(ContractPeriod.earliest_permitted_start_date).to eq(third_oldest.started_on)
        end
      end

      context "on the last day of the contract period" do
        around do |example|
          travel_to(current.finished_on) do
            example.run
          end
        end

        it "returns the start date of the contract period two periods before the current one" do
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
    subject { FactoryBot.build(:contract_period, started_on: Date.current, finished_on: Date.yesterday) }

    it "prevents periods with a duration less than 1 day from being written to the database" do
      expect { subject.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /PG::DataException/)
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

  describe "#fully_scheduled?" do
    subject(:contract_period) { FactoryBot.create(:contract_period, :current) }

    let(:possible_schedules) { Schedule.identifiers.values }

    context "when all possible schedules have been allocated to the contract period" do
      before do
        possible_schedules.each do |identifier|
          FactoryBot.create(:schedule, identifier:, contract_period:)
        end
      end

      it { is_expected.to be_fully_scheduled }
    end

    context "when only some schedules have been allocated to the contract period" do
      before do
        possible_schedules.take(2).each do |identifier|
          FactoryBot.create(:schedule, identifier:, contract_period:)
        end
      end

      it { is_expected.not_to be_fully_scheduled }
    end
  end

  describe "#editable?" do
    subject { FactoryBot.create(:contract_period, started_on:) }

    context "when the contract period has not yet started" do
      let(:started_on) { 1.month.from_now }

      it { is_expected.to be_editable }
    end

    context "when the contract period starts today" do
      let(:started_on) { Time.zone.today }

      it { is_expected.not_to be_editable }
    end

    context "when the contract period has already started" do
      let(:started_on) { 1.month.ago }

      it { is_expected.not_to be_editable }
    end
  end

  describe "#available_schedules" do
    subject(:contract_period) { FactoryBot.create(:contract_period) }

    context "without associated schedules" do
      it "lists all possible schedules" do
        expect(contract_period.available_schedules).to eq(Schedule.identifiers.keys)
      end
    end

    context "with associated schedules" do
      let(:associated_schedules) do
        %w[
          ecf-reduced-april
          ecf-standard-april
          ecf-standard-september
          ecf-reduced-january
          ecf-standard-january
          ecf-reduced-september
        ]
      end

      before do
        associated_schedules.each do |identifier|
          FactoryBot.create(:schedule, identifier:, contract_period:)
        end
      end

      it "lists any remaining schedules" do
        expect(contract_period.available_schedules).to eq(Schedule.identifiers.keys - associated_schedules)
      end
    end
  end

  describe "#sorted_schedules" do
    subject(:contract_period) { FactoryBot.create(:contract_period) }

    let(:associated_schedules) do
      %w[
        ecf-reduced-april
        ecf-standard-april
        ecf-standard-september
        ecf-reduced-january
        ecf-standard-january
        ecf-reduced-september
      ]
    end

    before do
      associated_schedules.each do |identifier|
        FactoryBot.create(:schedule, identifier:, contract_period:)
      end
    end

    it "orders schedules by identifier as defined in the enum" do
      expect(contract_period.sorted_schedules.map(&:identifier)).to eq(%w[
        ecf-standard-january
        ecf-standard-april
        ecf-standard-september
        ecf-reduced-january
        ecf-reduced-april
        ecf-reduced-september
      ])
    end
  end
end
