describe RegistrationPeriod do
  describe "associations" do
    it { is_expected.to have_many(:lead_provider_active_periods) }
  end

  describe "validations" do
    subject { FactoryBot.build(:registration_period) }

    it { is_expected.to validate_presence_of(:year) }
    it { is_expected.to validate_uniqueness_of(:year) }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than_or_equal_to(2020) }

    it { is_expected.to validate_presence_of(:started_on).with_message('Enter a start date') }
    it { is_expected.to validate_presence_of(:finished_on).with_message('Enter an end date') }

    describe '#no_overlaps' do
      before { FactoryBot.create(:registration_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 2, 2)) }

      it 'allows new records that do not overlap' do
        non_overlapping = FactoryBot.build(:registration_period, started_on: Date.new(2024, 2, 2), finished_on: Date.new(2024, 3, 3))
        expect(non_overlapping).to be_valid
      end

      it 'does not allow overlapping records' do
        overlapping = FactoryBot.build(:registration_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 3, 3))
        expect(overlapping).not_to be_valid
        expect(overlapping.errors.messages[:base]).to include(/Registration period overlaps/)
      end
    end
  end
end
