describe Teacher do
  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:teacher) }
    let(:target) { instance }

    def generate_new_value(attribute_to_change:)
      return 1.day.ago if attribute_to_change == :mentor_became_ineligible_for_funding_on
      return "started_not_completed" if attribute_to_change == :mentor_became_ineligible_for_funding_reason

      super(attribute_to_change:)
    end

    def will_change_attribute(attribute_to_change:, new_value:) # rubocop:disable Lint/UnusedMethodArgument
      instance.mentor_became_ineligible_for_funding_on = 1.day.ago if attribute_to_change == :mentor_became_ineligible_for_funding_reason
      instance.mentor_became_ineligible_for_funding_reason = "started_not_completed" if attribute_to_change == :mentor_became_ineligible_for_funding_on
    end

    it_behaves_like "a declarative metadata model", on_event: %i[create]
    it_behaves_like "a declarative metadata model", when_changing: %i[mentor_became_ineligible_for_funding_on mentor_became_ineligible_for_funding_reason], on_event: %i[update]
  end

  describe "associations" do
    it { is_expected.to have_many(:ect_at_school_periods) }
    it { is_expected.to have_many(:mentor_at_school_periods) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:appropriate_bodies).through(:induction_periods) }
    it { is_expected.to have_many(:induction_extensions) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:teacher_id_changes) }
    it { is_expected.to have_one(:started_induction_period).class_name("InductionPeriod") }
    it { is_expected.to have_one(:finished_induction_period).class_name("InductionPeriod") }
    it { is_expected.to have_one(:metadata).class_name("Metadata::Teacher") }

    describe ".started_induction_period" do
      subject { teacher.started_induction_period }

      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to be_nil }

      context "when there is an induction period" do
        let!(:induction_period) { FactoryBot.create(:induction_period, started_on: 1.year.ago, teacher:) }

        it { is_expected.to eq(induction_period) }
      end

      context "when there are multiple induction periods" do
        let!(:latest_induction_period) { FactoryBot.create(:induction_period, started_on: 1.year.ago, teacher:) }
        let!(:earliest_induction_period) { FactoryBot.create(:induction_period, started_on: 2.years.ago, teacher:) }

        it { is_expected.to eq(earliest_induction_period) }
      end
    end

    describe ".finished_induction_period" do
      subject { teacher.finished_induction_period }

      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to be_nil }

      context "when there is an induction period without an outcome" do
        before { FactoryBot.create(:induction_period, started_on: 1.year.ago, finished_on: 1.month.ago, teacher:) }

        it { is_expected.to be_nil }
      end

      context "when there is an induction period with an outcome" do
        let!(:induction_period) { FactoryBot.create(:induction_period, :pass, started_on: 1.year.ago, finished_on: 1.month.ago, teacher:) }

        it { is_expected.to eq(induction_period) }
      end

      context "when there are multiple induction periods, all without an outcome" do
        let!(:earliest_induction_period) { FactoryBot.create(:induction_period, started_on: 6.months.ago, finished_on: 3.months.ago, teacher:) }
        let!(:latest_induction_period) { FactoryBot.create(:induction_period, started_on: 3.months.ago, finished_on: 1.day.ago, teacher:) }

        it { is_expected.to be_nil }
      end

      context "when there are multiple induction periods, with and without outcomes" do
        let!(:earliest_induction_period) { FactoryBot.create(:induction_period, started_on: 6.months.ago, finished_on: 3.months.ago, teacher:) }
        let!(:latest_induction_period) { FactoryBot.create(:induction_period, :pass, started_on: 3.months.ago, finished_on: 1.day.ago, teacher:) }

        it { is_expected.to eq(latest_induction_period) }
      end
    end

    describe '.current_or_next_ect_at_school_period' do
      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to have_one(:current_or_next_ect_at_school_period).class_name('ECTAtSchoolPeriod') }

      context 'when there is a current period' do
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }
        let!(:finished_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 10.years.ago, finished_on: 8.years.ago, teacher:) }

        it 'returns the current ect_at_school_period' do
          expect(teacher.current_or_next_ect_at_school_period).to eql(ect_at_school_period)
        end
      end

      context 'when there is a current period and a future period' do
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, finished_on: 2.weeks.from_now, teacher:) }
        let!(:future_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 2.weeks.from_now, finished_on: nil, teacher:) }

        it 'returns the current ect_at_school_period' do
          expect(teacher.current_or_next_ect_at_school_period).to eql(ect_at_school_period)
        end
      end

      context 'when there is no current period' do
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :finished, teacher:) }

        it 'returns nil' do
          expect(teacher.current_or_next_ect_at_school_period).to be_nil
        end
      end
    end

    it "returns the appropriate body from the ongoing induction period" do
      teacher = FactoryBot.create(:teacher)
      other_appropriate_body = FactoryBot.create(:appropriate_body)
      _other_induction_period = FactoryBot.create(
        :induction_period,
        teacher:,
        appropriate_body: other_appropriate_body,
        started_on: 2.years.ago,
        finished_on: 1.year.ago
      )
      appropriate_body = FactoryBot.create(:appropriate_body)
      _ongoing_induction_period = FactoryBot.create(
        :induction_period,
        teacher:,
        appropriate_body:,
        started_on: 1.year.ago,
        finished_on: nil,
        number_of_terms: nil
      )

      expect(teacher.current_appropriate_body).to eq(appropriate_body)
    end

    it "returns nil when the teacher has no ongoing induction period" do
      teacher = FactoryBot.create(:teacher)
      other_appropriate_body = FactoryBot.create(:appropriate_body)
      _other_induction_period = FactoryBot.create(
        :induction_period,
        teacher:,
        appropriate_body: other_appropriate_body,
        started_on: 2.years.ago,
        finished_on: 1.year.ago
      )
      appropriate_body = FactoryBot.create(:appropriate_body)
      _ongoing_induction_period = FactoryBot.create(
        :induction_period,
        teacher:,
        appropriate_body:,
        started_on: 1.year.ago,
        finished_on: 2.weeks.ago
      )

      expect(teacher.current_appropriate_body).to be_nil
    end
  end

  describe "validations" do
    subject { FactoryBot.build(:teacher) }

    it { is_expected.to validate_length_of(:trs_induction_status).with_message('TRS induction status must be shorter than 18 characters') }

    it { is_expected.to validate_uniqueness_of(:api_user_id).case_insensitive.with_message("API user id already exists for another teacher") }
    it { is_expected.to validate_uniqueness_of(:api_ect_training_record_id).case_insensitive.with_message("API ect training record id already exists for another teacher") }
    it { is_expected.to validate_uniqueness_of(:api_mentor_training_record_id).case_insensitive.with_message("API mentor training record id already exists for another teacher") }

    describe ".first_became_eligible_for_ect_training_at, .first_became_eligible_for_mentor_training_at" do
      context "when not yet set" do
        subject { FactoryBot.create(:teacher, first_became_eligible_for_ect_training_at: nil, first_became_eligible_for_mentor_training_at: nil) }

        it { is_expected.to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_ect_training_at) }
        it { is_expected.to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_mentor_training_at) }
      end

      context "when already set" do
        subject { FactoryBot.create(:teacher, first_became_eligible_for_ect_training_at: time, first_became_eligible_for_mentor_training_at: time) }

        let(:time) { Time.zone.now }

        it { is_expected.not_to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_ect_training_at) }
        it { is_expected.to allow_value(time).for(:first_became_eligible_for_ect_training_at) }

        it { is_expected.not_to allow_values("", " ", nil, "test", Date.new).for(:first_became_eligible_for_mentor_training_at) }
        it { is_expected.to allow_value(time).for(:first_became_eligible_for_mentor_training_at) }
      end
    end

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

  describe "normalizing" do
    subject { FactoryBot.build(:teacher, corrected_name: " Tobias Menzies ") }

    it "removes leading and trailing spaces from the corrected name" do
      expect(subject.corrected_name).to eql("Tobias Menzies")
    end
  end

  describe "#eligible_for_ect_training?" do
    subject(:teacher) { FactoryBot.create(:teacher) }

    it { is_expected.not_to be_eligible_for_ect_training }

    context "when there is an ongoing induction period and ect at school period" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
      end

      it { is_expected.to be_eligible_for_ect_training }
    end

    context "when there is an ongoing induction period and an ect at school period that has finished" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :finished, teacher:)
      end

      it { is_expected.not_to be_eligible_for_ect_training }
    end

    context "when there is an ongoing induction period but no ect at school period" do
      before { FactoryBot.create(:induction_period, :ongoing, teacher:) }

      it { is_expected.not_to be_eligible_for_ect_training }
    end

    context "when there is an ongoing ect at school. period but no induction period" do
      before { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:) }

      it { is_expected.not_to be_eligible_for_ect_training }
    end
  end

  describe "#eligible_for_mentor_training?" do
    subject(:teacher) { FactoryBot.create(:teacher) }

    it { is_expected.to be_eligible_for_mentor_training }

    context "when the mentor became ineligible for funding" do
      subject(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }

      it { is_expected.not_to be_eligible_for_ect_training }
    end
  end
end
