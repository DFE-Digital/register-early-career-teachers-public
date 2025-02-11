describe Teacher do
  describe "associations" do
    it { is_expected.to have_many(:ect_at_school_periods) }
    it { is_expected.to have_many(:mentor_at_school_periods) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:induction_extensions) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.build(:teacher) }

    it { is_expected.to validate_presence_of(:trs_first_name) }
    it { is_expected.to validate_presence_of(:trs_last_name) }
    it { is_expected.to validate_uniqueness_of(:trn).with_message('TRN already exists').case_insensitive }

    describe "trn" do
      context "when the string contains 7 numeric digits" do
        %w[0000001 9999999].each do |value|
          it { is_expected.to allow_value(value).for(:trn) }
        end
      end

      context "when the string contains less than 5 numeric digits or more than 7 numeric digits" do
        %w[1234 12345678 ONE4567 1234!].each do |value|
          it { is_expected.not_to allow_value(value).for(:trn) }
        end
      end
    end
  end

  describe 'scopes' do
    describe '#search' do
      it "searches the 'search' column using a tsquery" do
        expect(Teacher.search('Joey').to_sql).to end_with(%{WHERE (teachers.search @@ to_tsquery('unaccented', 'Joey:*'))})
      end

      describe 'basic matching' do
        let!(:target) { FactoryBot.create(:teacher, trs_first_name: "Malcolm", trs_last_name: "Wilkerson", corrected_name: nil) }
        let!(:other) { FactoryBot.create(:teacher, trs_first_name: "Reese", trs_last_name: "Wilkerson", corrected_name: nil) }

        it "returns only the expected result" do
          results = Teacher.search('Malcolm')

          expect(results).to include(target)
          expect(results).not_to include(other)
        end
      end

      describe 'matching with accents' do
        let!(:target) { FactoryBot.create(:teacher, trs_first_name: "Stëvìê", trs_last_name: "Kènårbän", corrected_name: nil) }

        it 'matches when names have accents but search terms do not' do
          results = Teacher.search('Stevie Kenarban')

          expect(results).to include(target)
        end

        it 'matches when names and search terms both have accents ' do
          results = Teacher.search('Stëvìê Kènårbän')

          expect(results).to include(target)
        end
      end

      describe 'matching a prefix' do
        let!(:target) { FactoryBot.create(:teacher, trs_first_name: "Dewey", trs_last_name: "Wilkerson", corrected_name: nil) }
        let!(:other) { FactoryBot.create(:teacher, trs_first_name: "Reese", trs_last_name: "Wilkerson", corrected_name: nil) }

        it 'matches on the start of a word' do
          results = Teacher.search('Dew')

          expect(results).to include(target)
        end

        it 'matches on multiple starts of words' do
          results = Teacher.search('Dew Wil')

          expect(results).to include(target)
        end

        it 'only on multiple starts when all match part of the name' do
          results = Teacher.search('Dew Wil')

          expect(results).not_to include(other)
        end
      end
    end
  end
end
