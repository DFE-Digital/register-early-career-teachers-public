describe ContractPeriod do
  describe "associations" do
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:active_lead_providers).inverse_of(:contract_period) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).through(:active_lead_providers) }
  end

  describe "validations" do
    subject { FactoryBot.build(:contract_period) }

    it { is_expected.to validate_presence_of(:year) }
    it { is_expected.to validate_uniqueness_of(:year) }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than_or_equal_to(2020) }

    it { is_expected.to validate_presence_of(:started_on).with_message('Enter a start date') }
    it { is_expected.to validate_presence_of(:finished_on).with_message('Enter an end date') }

    describe '#no_overlaps' do
      before { FactoryBot.create(:contract_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 2, 2)) }

      it 'allows new records that do not overlap' do
        non_overlapping = FactoryBot.build(:contract_period, started_on: Date.new(2024, 2, 2), finished_on: Date.new(2024, 3, 3))
        expect(non_overlapping).to be_valid
      end

      it 'does not allow overlapping records' do
        overlapping = FactoryBot.build(:contract_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 3, 3))
        expect(overlapping).not_to be_valid
        expect(overlapping.errors.messages[:base]).to include(/Contract period overlaps/)
      end
    end
  end

  describe '.containing_date' do
    let!(:period) do
      FactoryBot.create(:contract_period, started_on: Date.new(2024, 9, 1), finished_on: Date.new(2025, 8, 31))
    end

    it 'returns the contract_period containing the given date' do
      expect(ContractPeriod.containing_date(Date.new(2025, 1, 1))).to eq(period)
    end

    it 'returns nil when no period contains the date' do
      expect(ContractPeriod.containing_date(Date.new(2023, 1, 1))).to be_nil
    end
  end

  describe '.earliest_permitted_start_date' do
    context 'when there are contract periods' do
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

      it 'returns the start date of the contract period two periods before the current one' do
        freeze_time do
          expect(ContractPeriod.earliest_permitted_start_date).to eq(third_oldest.started_on)
        end
      end
    end

    context 'when there are no current contract periods' do
      it 'returns nil' do
        freeze_time do
          expect(ContractPeriod.earliest_permitted_start_date).to be_nil
          expect(ContractPeriod.count).to eq(0)
        end
      end
    end
  end
end
