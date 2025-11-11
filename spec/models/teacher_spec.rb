describe Teacher do
  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:teacher) }
    let(:target) { instance }

    it_behaves_like "a declarative metadata model", on_event: %i[create update]
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:teacher) }
    let(:target) { instance }

    it_behaves_like "a declarative touch model", when_changing: %i[api_id
                                                                   trs_first_name
                                                                   trs_last_name
                                                                   trn
                                                                   api_ect_training_record_id
                                                                   api_mentor_training_record_id
                                                                   mentor_became_ineligible_for_funding_on
                                                                   mentor_became_ineligible_for_funding_reason
                                                                   ect_first_became_eligible_for_training_at
                                                                   mentor_first_became_eligible_for_training_at
                                                                   ect_pupil_premium_uplift
                                                                   ect_sparsity_uplift
                                                                   ect_payments_frozen_year
                                                                   mentor_payments_frozen_year], timestamp_attribute: :api_updated_at
  end

  describe "associations" do
    it { is_expected.to have_many(:ect_at_school_periods) }
    it { is_expected.to have_many(:mentor_at_school_periods) }
    it { is_expected.to have_many(:ect_training_periods).through(:ect_at_school_periods) }
    it { is_expected.to have_many(:mentor_training_periods).through(:mentor_at_school_periods) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:appropriate_bodies).through(:induction_periods) }
    it { is_expected.to have_many(:induction_extensions) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:teacher_id_changes) }
    it { is_expected.to have_many(:lead_provider_metadata).class_name("Metadata::TeacherLeadProvider") }
    it { is_expected.to have_one(:started_induction_period).class_name("InductionPeriod") }
    it { is_expected.to have_one(:finished_induction_period).class_name("InductionPeriod") }
    it { is_expected.to have_one(:earliest_ect_at_school_period).class_name("ECTAtSchoolPeriod") }
    it { is_expected.to have_one(:earliest_mentor_at_school_period).class_name("MentorAtSchoolPeriod") }

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

    describe ".earliest_ect_at_school_period" do
      subject { teacher.earliest_ect_at_school_period }

      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to be_nil }

      context "when there is an ECT at school period" do
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, teacher:) }

        it { is_expected.to eq(ect_at_school_period) }
      end

      context "when there are multiple ECT at school periods" do
        let!(:latest_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 1.year.ago, teacher:) }
        let!(:earliest_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 2.years.ago, teacher:) }

        it { is_expected.to eq(earliest_ect_at_school_period) }
      end
    end

    describe ".earliest_mentor_at_school_period" do
      subject { teacher.earliest_mentor_at_school_period }

      let(:teacher) { FactoryBot.create(:teacher) }

      it { is_expected.to be_nil }

      context "when there is an mentor at school period" do
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, teacher:) }

        it { is_expected.to eq(mentor_at_school_period) }
      end

      context "when there are multiple mentor at school periods" do
        let!(:latest_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: 1.year.ago, teacher:) }
        let!(:earliest_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: 2.years.ago, teacher:) }

        it { is_expected.to eq(earliest_mentor_at_school_period) }
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

    describe "training_periods" do
      context "ect_training_periods" do
        it "returns training periods associated with the teacher's ect at school periods" do
          teacher = FactoryBot.create(:teacher)
          ect_at_school_period = FactoryBot.create(:ect_at_school_period, teacher:)
          ect_training_period = FactoryBot.create(:training_period, :for_ect, ect_at_school_period:)

          other_ect_at_school_period = FactoryBot.create(:ect_at_school_period)
          FactoryBot.create(:training_period, :for_ect, ect_at_school_period: other_ect_at_school_period)

          expect(teacher.ect_training_periods).to contain_exactly(ect_training_period)
        end
      end

      context "mentor_training_periods" do
        it "returns training periods associated with the teacher's mentor at school periods" do
          teacher = FactoryBot.create(:teacher)
          mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, teacher:)
          mentor_training_period = FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:)

          other_mentor_at_school_period = FactoryBot.create(:mentor_at_school_period)
          FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: other_mentor_at_school_period)

          expect(teacher.mentor_training_periods).to contain_exactly(mentor_training_period)
        end
      end
    end
  end

  describe "validations" do
    subject { FactoryBot.build(:teacher, trn:) }

    let(:trn) { '1234567' }

    it { is_expected.to validate_length_of(:trs_induction_status).with_message('TRS induction status must be shorter than 18 characters') }

    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another teacher") }
    it { is_expected.to validate_uniqueness_of(:api_ect_training_record_id).case_insensitive.with_message("API ect training record id already exists for another teacher").allow_nil }
    it { is_expected.to validate_uniqueness_of(:api_mentor_training_record_id).case_insensitive.with_message("API mentor training record id already exists for another teacher").allow_nil }

    describe "trn" do
      it { is_expected.to validate_presence_of(:trn).with_message('Enter the teacher reference number (TRN)') }
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

      describe 'allowing some legacy (ECF1) teachers to have no TRN' do
        context 'when not trnless (default)' do
          it { is_expected.to validate_presence_of(:trn).with_message('Enter the teacher reference number (TRN)') }
          it { is_expected.not_to allow_value(nil).for(:trn) }
          it { is_expected.to allow_value(trn).for(:trn) }
        end

        context 'when trnless' do
          subject { FactoryBot.build(:teacher, trnless: true) }

          it { is_expected.to validate_absence_of(:trn).with_message('TRN not allowed when trnless is true') }
          it { is_expected.to allow_value(nil).for(:trn) }
          it { is_expected.not_to allow_value(trn).for(:trn) }
        end

        describe 'checking at the database level' do
          it 'prevents a row from being inserted when trn is missing and trnless is false' do
            expected_error = /new row for relation "teachers" violates check constraint "check_trn_presence"/

            expect { FactoryBot.build(:teacher, trn: nil, trnless: false).save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, expected_error)
          end
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

        it 'has validation errors on the ineligibility date field' do
          subject.valid?

          expected_message = /Enter the date when the mentor became ineligible for funding/
          expect(subject.errors.messages[:mentor_became_ineligible_for_funding_on]).to include(expected_message)
        end
      end

      context 'when the ineligibility reason is present but the date is missing' do
        subject { FactoryBot.build(:teacher, mentor_became_ineligible_for_funding_on: 3.days.ago) }

        it { is_expected.to be_invalid }

        it 'has validation errors on the ineligibility date field' do
          subject.valid?

          expected_message = /Choose the reason why the mentor became ineligible for funding/
          expect(subject.errors.messages[:mentor_became_ineligible_for_funding_reason]).to include(expected_message)
        end
      end
    end

    describe ".ect_first_became_eligible_for_training_at, .mentor_first_became_eligible_for_training_at" do
      context "when not yet set" do
        subject { FactoryBot.create(:teacher, ect_first_became_eligible_for_training_at: nil, mentor_first_became_eligible_for_training_at: nil) }

        it { is_expected.to allow_values("", " ", nil, "test", Date.new).for(:ect_first_became_eligible_for_training_at) }
        it { is_expected.to allow_values("", " ", nil, "test", Date.new).for(:mentor_first_became_eligible_for_training_at) }
      end

      context "when already set" do
        subject { FactoryBot.create(:teacher, ect_first_became_eligible_for_training_at: time, mentor_first_became_eligible_for_training_at: time) }

        let(:time) { Time.zone.now }

        it { is_expected.not_to allow_values("", " ", nil, "test", Date.new).for(:ect_first_became_eligible_for_training_at) }
        it { is_expected.to allow_value(time).for(:ect_first_became_eligible_for_training_at) }

        it { is_expected.not_to allow_values("", " ", nil, "test", Date.new).for(:mentor_first_became_eligible_for_training_at) }
        it { is_expected.to allow_value(time).for(:mentor_first_became_eligible_for_training_at) }
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
end
