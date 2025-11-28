describe ECF2TeacherHistory do
  subject { ECF2TeacherHistory.new(teacher_row:, **other_arguments) }

  let(:trn) { "2345678" }
  let(:trs_first_name) { "Colin" }
  let(:trs_last_name) { "Jeavons" }
  let(:corrected_name) { "Colin Abel Jeavons" }
  let(:teacher_row) { ECF2TeacherHistory::TeacherRow.new(trn:, trs_first_name:, trs_last_name:, corrected_name:) }

  let(:mentorship_period_rows) do
    [ECF2TeacherHistory::MentorshipPeriodRow.new(started_on: 1.month.ago.to_date, finished_on: 1.week.ago.to_date)]
  end

  let(:training_period_rows) do
    [ECF2TeacherHistory::TrainingPeriodRow.new(started_on: 1.month.ago.to_date, finished_on: 1.week.ago.to_date)]
  end

  let(:ect_at_school_period_rows) do
    [
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        mentorship_period_rows:,
        training_period_rows:
      )
    ]
  end

  let(:mentor_at_school_period_rows) do
    [
      ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        mentorship_period_rows:
      )
    ]
  end

  let(:other_arguments) { {} }

  describe "#initialize" do
    it "is initialized with a teacher row" do
      expect(subject.teacher_row.trn).to eql(trn)
      expect(subject.teacher_row.trs_first_name).to eql(trs_first_name)
      expect(subject.teacher_row.trs_last_name).to eql(trs_last_name)
      expect(subject.teacher_row.corrected_name).to eql(corrected_name)
    end

    context "when ect_at_school_period_rows are present" do
      let(:other_arguments) { { ect_at_school_period_rows: } }

      it "can be initialized with ect_at_school_period_rows" do
        expect(subject.ect_at_school_period_rows).to eql(ect_at_school_period_rows)
      end
    end

    context "when mentor_at_school_period_rows are present" do
      let(:other_arguments) { { mentor_at_school_period_rows: } }

      it "can be initialized with mentor_at_school_period_rows" do
        expect(subject.mentor_at_school_period_rows).to eql(mentor_at_school_period_rows)
      end
    end
  end

  describe "#save_all!" do
    let(:contract_period) { FactoryBot.create(:contract_period) }

    it { is_expected.to respond_to(:save_all!) }

    describe "saving a teacher" do
      let(:api_id) { SecureRandom.uuid }
      let(:api_ect_training_record_id) { SecureRandom.uuid }
      let(:api_mentor_training_record_id) { SecureRandom.uuid }
      let(:ect_pupil_premium_uplift) { true }
      let(:ect_sparsity_uplift) { true }
      let(:ect_first_became_eligible_for_training_at) { 3.years.ago.round(2) }
      let(:ect_payments_frozen_year) { contract_period.year }
      let(:mentor_became_ineligible_for_funding_on) { 2.years.ago.to_date }
      let(:mentor_became_ineligible_for_funding_reason) { "completed_declaration_received" }
      let(:mentor_first_became_eligible_for_training_at) { 2.years.ago.round(2) }
      let(:mentor_payments_frozen_year) { contract_period.year }

      let(:teacher_row) do
        ECF2TeacherHistory::TeacherRow.new(
          trn:,
          trs_first_name:,
          trs_last_name:,
          corrected_name:,

          api_id:,
          api_ect_training_record_id:,
          api_mentor_training_record_id:,

          ect_pupil_premium_uplift:,
          ect_sparsity_uplift:,
          ect_first_became_eligible_for_training_at:,
          ect_payments_frozen_year:,

          mentor_became_ineligible_for_funding_on:,
          mentor_became_ineligible_for_funding_reason:,
          mentor_first_became_eligible_for_training_at:,
          mentor_payments_frozen_year:
        )
      end

      it "saves a row with the right values" do
        teacher = subject.save_all!

        expect(teacher).to be_persisted

        aggregate_failures do
          expect(teacher.trn).to eql(trn)
          expect(teacher.trs_first_name).to eql(trs_first_name)
          expect(teacher.trs_last_name).to eql(trs_last_name)
          expect(teacher.corrected_name).to eql(corrected_name)

          expect(teacher.api_id).to eql(api_id)
          expect(teacher.api_ect_training_record_id).to eql(api_ect_training_record_id)
          expect(teacher.api_mentor_training_record_id).to eql(api_mentor_training_record_id)

          expect(teacher.ect_pupil_premium_uplift).to eql(ect_pupil_premium_uplift)
          expect(teacher.ect_sparsity_uplift).to eql(ect_sparsity_uplift)
          expect(teacher.ect_first_became_eligible_for_training_at).to eql(ect_first_became_eligible_for_training_at)
          expect(teacher.ect_payments_frozen_year).to eql(ect_payments_frozen_year)

          expect(teacher.mentor_became_ineligible_for_funding_on).to eql(mentor_became_ineligible_for_funding_on)
          expect(teacher.mentor_became_ineligible_for_funding_reason).to eql(mentor_became_ineligible_for_funding_reason)
          expect(teacher.mentor_first_became_eligible_for_training_at).to eql(mentor_first_became_eligible_for_training_at)
          expect(teacher.mentor_payments_frozen_year).to eql(mentor_payments_frozen_year)
        end
      end
    end
  end
end
