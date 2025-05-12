describe Teacher do
  describe "associations" do
    it { is_expected.to have_many(:ect_at_school_periods) }
    it { is_expected.to have_many(:mentor_at_school_periods) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:appropriate_bodies).through(:induction_periods) }
    it { is_expected.to have_many(:induction_extensions) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.build(:teacher) }

    it { is_expected.to validate_presence_of(:trs_first_name) }
    it { is_expected.to validate_presence_of(:trs_last_name) }
    it { is_expected.to validate_length_of(:trs_induction_status).with_message('TRS induction status must be shorter than 18 characters') }

    describe "trn" do
      it { is_expected.to validate_uniqueness_of(:trn).with_message('TRN already exists').case_insensitive }

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

    describe 'mentor ineligibility' do
      context 'when both the ineligibility date and reason are present' do
        subject { FactoryBot.build(:teacher) }

        it { is_expected.to be_valid }
      end

      context 'when both the ineligibility date and reason are blank' do
        subject { FactoryBot.build(:teacher, :ineligible_for_mentor_funding) }

        it { is_expected.to be_valid }
      end

      context 'when the ineligibility date is present but the reason is missing' do
        subject { FactoryBot.build(:teacher, mentor_became_ineligible_for_funding_reason: 'started_not_completed') }

        it { is_expected.to be_invalid }

        it 'has validation errors on the ineligibilty date field' do
          subject.valid?

          expected_message = /Enter the date when the mentor became ineligible for funding/
          expect(subject.errors.messages[:mentor_became_ineligible_for_funding_on]).to include(expected_message)
        end
      end

      context 'when the ineligibility reason is present but the date is missing' do
        subject { FactoryBot.build(:teacher, mentor_became_ineligible_for_funding_on: 3.days.ago) }

        it { is_expected.to be_invalid }

        it 'has validation errors on the ineligibilty date field' do
          subject.valid?

          expected_message = /Choose the reason why the mentor became ineligible for funding/
          expect(subject.errors.messages[:mentor_became_ineligible_for_funding_reason]).to include(expected_message)
        end
      end
    end
  end

  describe 'scopes' do
    describe '.search' do
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

    describe '.ordered_by_trs_data_last_refreshed_at_nulls_first' do
      it 'constructs the query so results are ascending but nulls are placed before the rows with values' do
        expected_clause = %(ORDER BY "teachers"."trs_data_last_refreshed_at" ASC NULLS FIRST)

        expect(Teacher.ordered_by_trs_data_last_refreshed_at_nulls_first.to_sql).to end_with(expected_clause)
      end
    end

    describe '.deactivated_in_trs' do
      it 'only includes records where trs_deactivated = TRUE' do
        expected_clause = %("teachers"."trs_deactivated" = TRUE)

        expect(Teacher.deactivated_in_trs.to_sql).to end_with(expected_clause)
      end
    end

    describe '.active_in_trs' do
      it 'only includes records where trs_deactivated = FALSE' do
        expected_clause = %("teachers"."trs_deactivated" = FALSE)

        expect(Teacher.active_in_trs.to_sql).to end_with(expected_clause)
      end
    end
  end
end
