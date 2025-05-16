describe Statement do
  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to have_many(:adjustments) }
  end

  describe "validations" do
    subject { FactoryBot.create(:statement) }

    it { is_expected.to validate_inclusion_of(:output_fee).in_array([true, false]).with_message("Output fee must be true or false") }
    it { is_expected.to validate_numericality_of(:month).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(12).with_message("Month must be a number between 1 and 12") }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than_or_equal_to(2020).with_message("Year must be on or after 2020 and on or before #{described_class.maximum_year}") }
    it { is_expected.to validate_uniqueness_of(:active_lead_provider_id).scoped_to(:year, :month).with_message("Statement with the same month and year already exists for the lead provider") }
    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another statement") }
  end

  describe ".maximum_year" do
    subject { described_class.maximum_year }

    it { is_expected.to eq(Date.current.year + 5) }
  end
end
