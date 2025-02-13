describe InductionExtension do
  describe "associations" do
    it { is_expected.to belong_to(:teacher) }
    it { is_expected.to have_many(:events) }
  end

  describe 'validation' do
    describe 'number_of_terms' do
      it 'allows valid values to be saved' do
        # NOTE: we're actually saving them here to ensure PostgreSQL's column accepts the necessary
        #       precision and scale
        expect(FactoryBot.create(:induction_extension, number_of_terms: 0.1)).to be_valid
        expect(FactoryBot.create(:induction_extension, number_of_terms: 15.9)).to be_valid
      end

      it 'prohibits numbers outside the range 1..16' do
        expect(subject).not_to allow_value(0).for(:number_of_terms)
        expect(subject).not_to allow_value(16.1).for(:number_of_terms)
      end

      context "when number_of_terms has more than 1 decimal place" do
        subject { FactoryBot.build(:induction_extension, number_of_terms: 3.45) }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:number_of_terms]).to include("Terms can only have up to 1 decimal place")
        end
      end

      context "when number_of_terms has 1 decimal place" do
        subject { FactoryBot.build(:induction_extension, number_of_terms: 3.5) }

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "when number_of_terms is an integer" do
        subject { FactoryBot.build(:induction_extension, number_of_terms: 3) }

        it "is valid" do
          expect(subject).to be_valid
        end
      end
    end
  end
end
