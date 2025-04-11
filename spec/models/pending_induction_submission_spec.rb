RSpec.describe PendingInductionSubmission do
  it { is_expected.to be_a_kind_of(Interval) }
  it { is_expected.to be_a_kind_of(SharedInductionPeriodValidation) }

  it_behaves_like 'an induction period'

  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body) }
    it { is_expected.to belong_to(:pending_induction_submission_batch).optional }
  end

  describe "validation" do
    it { is_expected.to validate_presence_of(:appropriate_body_id).with_message("Select an appropriate body") }

    describe "trn" do
      it { is_expected.to validate_presence_of(:trn).on(:find_ect).with_message("Enter a TRN") }

      context "when the string contains 7 numeric digits" do
        %w[0000001 9999999].each do |value|
          it { is_expected.to allow_value(value).for(:trn) }
        end
      end

      context "when the string contains something other than 7 numeric digits" do
        %w[123456 12345678 ONE4567 123456!].each do |value|
          it { is_expected.not_to allow_value(value).for(:trn).on(:find_ect) }
        end
      end
    end

    describe "trs_induction_status" do
      let(:statuses) { %w[None RequiredToComplete Exempt InProgress Passed Failed FailedInWales] }

      it { is_expected.to validate_presence_of(:trs_induction_status).on(:register_ect).with_message("TRS Induction Status is not known") }
      it { is_expected.to allow_values(*statuses).for(:trs_induction_status) }
    end

    describe "date_of_birth" do
      it { is_expected.to validate_presence_of(:date_of_birth).with_message("Enter a date of birth").on(:find_ect) }

      it { is_expected.to validate_inclusion_of(:date_of_birth).in_range(100.years.ago.to_date..18.years.ago.to_date).on(:find_ect).with_message("Teacher must be between 18 and 100 years old") }
    end

    describe "establishment_id" do
      it { is_expected.to allow_value(nil).for(:establishment_id) }

      describe "valid" do
        ["1111/111", "9999/999"].each do |id|
          it { is_expected.to allow_value(id).for(:establishment_id).on(:find_ect) }
        end
      end

      describe "invalid" do
        ["111/1111", "AAAA/BBB", "1234/12345"].each do |id|
          it { is_expected.not_to allow_value(id).for(:establishment_id).on(:find_ect).with_message("Enter an establishment ID in the format 1234/567") }
        end
      end
    end

    describe "induction_programme" do
      it { is_expected.to validate_inclusion_of(:induction_programme).in_array(%w[fip cip diy]).with_message("Choose an induction programme").on(:register_ect) }
    end

    describe "started_on" do
      it { is_expected.to validate_presence_of(:started_on).with_message("Enter a start date").on(:register_ect) }
    end

    describe "finished_on" do
      it { is_expected.to validate_presence_of(:finished_on).with_message("Enter a finish date").on(%i[release_ect record_outcome]) }
    end

    describe "number_of_terms" do
      subject { FactoryBot.build(:pending_induction_submission, finished_on: Date.current) }

      it { is_expected.to validate_presence_of(:number_of_terms).with_message('Enter a number of terms').on(%i[release_ect record_outcome]) }
      it { is_expected.to validate_inclusion_of(:number_of_terms).in_range(0..16).with_message("Number of terms must be between 0 and 16").on(%i[release_ect record_outcome]) }

      context "when finished_on is blank" do
        subject { FactoryBot.build(:pending_induction_submission, finished_on: nil) }

        it "validates absence of number_of_terms" do
          subject.number_of_terms = 5
          subject.valid?(:release_ect)
          expect(subject.errors[:number_of_terms]).to include("Delete the number of terms if the induction has no end date")
        end
      end

      context "when number_of_terms has more than 1 decimal place" do
        subject { FactoryBot.build(:pending_induction_submission, appropriate_body:, number_of_terms: 3.45, finished_on: Date.current) }

        let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

        it "is invalid on release_ect" do
          expect(subject.valid?(:release_ect)).to be false
          expect(subject.errors[:number_of_terms]).to include("Terms can only have up to 1 decimal place")
        end

        it "is invalid on record_outcome" do
          expect(subject.valid?(:record_outcome)).to be false
          expect(subject.errors[:number_of_terms]).to include("Terms can only have up to 1 decimal place")
        end
      end

      context "when number_of_terms has 1 decimal place" do
        subject { FactoryBot.build(:pending_induction_submission, appropriate_body:, number_of_terms: 3.5, finished_on: Date.current) }

        let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

        it "is valid on release_ect" do
          expect(subject.valid?(:release_ect)).to be true
        end

        it "is valid on record_outcome" do
          subject.outcome = "pass"
          expect(subject.valid?(:record_outcome)).to be true
        end
      end

      context "when number_of_terms is an integer" do
        subject { FactoryBot.build(:pending_induction_submission, appropriate_body:, number_of_terms: 3, finished_on: Date.current) }

        let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

        it "is valid on release_ect" do
          expect(subject.valid?(:release_ect)).to be true
        end

        it "is valid on record_outcome" do
          subject.outcome = "pass"
          expect(subject.valid?(:record_outcome)).to be true
        end
      end
    end

    describe "confirmed" do
      it { is_expected.to validate_acceptance_of(:confirmed).on(:check_ect).with_message("Confirm if these details are correct or try your search again") }
    end

    describe "started_on_not_in_future" do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

      context "when started_on is today" do
        before { pending_induction_submission.started_on = Date.current }

        it "is valid" do
          expect(pending_induction_submission).to be_valid
        end
      end

      context "when started_on is in the past" do
        before { pending_induction_submission.started_on = Date.current - 1.day }

        it "is valid" do
          expect(pending_induction_submission).to be_valid
        end
      end

      context "when started_on is in the future" do
        before { pending_induction_submission.started_on = Date.current + 1.day }

        it "is invalid" do
          expect(pending_induction_submission).not_to be_valid
        end

        it "adds the correct error message" do
          pending_induction_submission.valid?
          expect(pending_induction_submission.errors[:started_on]).to include("Start date cannot be in the future")
        end
      end
    end

    describe "finished_on_not_in_future" do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

      context "when finished_on is today" do
        before do
          pending_induction_submission.finished_on = Date.current
          pending_induction_submission.number_of_terms = 1
        end

        it "is valid" do
          expect(pending_induction_submission).to be_valid
        end
      end

      context "when finished_on is in the past" do
        before do
          pending_induction_submission.finished_on = Date.current - 1.day
          pending_induction_submission.number_of_terms = 1
        end

        it "is valid" do
          expect(pending_induction_submission).to be_valid
        end
      end

      context "when finished_on is in the future" do
        before { pending_induction_submission.finished_on = Date.current + 1.day }

        it "is invalid" do
          expect(pending_induction_submission).not_to be_valid
        end

        it "adds the correct error message" do
          pending_induction_submission.valid?
          expect(pending_induction_submission.errors[:finished_on]).to include("End date cannot be in the future")
        end
      end
    end

    describe "start_date_after_qts_date" do
      let(:pending_induction_submission) { FactoryBot.build(:pending_induction_submission, started_on:, trs_qts_awarded_on: Date.new(2023, 5, 1)) }

      context "when trs_qts_awarded_on is before started_on" do
        let(:started_on) { Date.new(2023, 5, 2) }

        it "is valid" do
          pending_induction_submission.valid?(:register_ect)

          expect(pending_induction_submission.errors[:started_on]).to be_empty
        end
      end

      context "when trs_qts_awarded_on is after started_on" do
        let(:started_on) { Date.new(2023, 4, 1) }

        it "is invalid" do
          pending_induction_submission.valid?(:register_ect)

          expect(pending_induction_submission.errors[:started_on]).to include("Start date cannot be before QTS award date (1 May 2023)")
        end
      end
    end
  end

  describe '#fail?' do
    subject { FactoryBot.build(:pending_induction_submission, outcome: 'fail') }

    it { is_expected.to be_fail }
  end

  describe '#pass?' do
    subject { FactoryBot.build(:pending_induction_submission, outcome: 'pass') }

    it { is_expected.to be_pass }
  end

  describe '#exempt?' do
    subject { FactoryBot.build(:pending_induction_submission, trs_induction_status: 'Exempt') }

    it { is_expected.to be_exempt }
  end

  describe '#teacher' do
    let(:teacher) { FactoryBot.create(:teacher, trn: '1234567') }
    let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trn: teacher.trn) }

    it 'returns the teacher associated with the trn' do
      expect(pending_induction_submission.teacher).to eq(teacher)
    end
  end

  describe '#playback_errors' do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:pending_induction_submission) { FactoryBot.build(:pending_induction_submission, appropriate_body:, finished_on: 1.day.ago) }

    before do
      pending_induction_submission.playback_errors unless pending_induction_submission.save(context: :record_outcome)
    end

    it 'sets error_message as a sentence of joined messages' do
      expect(pending_induction_submission.error_message).to eq("Number of terms Enter a number of terms and Outcome Outcome must be either 'passed' or 'failed'")
    end
  end

  describe '#error_message' do
    let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, error_message: nil) }

    it 'returns a default message' do
      expect(pending_induction_submission.error_message).to eq("✅")
    end

    context 'when error_message is set' do
      before { pending_induction_submission.error_message = "Some error" }

      it 'returns the error message' do
        expect(pending_induction_submission.error_message).to eq("Some error")
      end
    end
  end
end
