describe PendingInductionSubmission do
  it { is_expected.to be_a_kind_of(Interval) }
  it { is_expected.to be_a_kind_of(SharedInductionPeriodValidation) }

  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body) }
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

      describe '#started_on_from_september_2021_onwards' do
        context 'when started_on before September 2021' do
          subject { FactoryBot.build(:pending_induction_submission, started_on:) }
          let(:started_on) { Date.new(2021, 8, 31) }
          before { subject.valid? }

          it 'has a suitable error message' do
            expect(subject.errors.messages[:started_on]).to include("Enter a start date after 1 September 2021")
          end
        end

        it { is_expected.not_to allow_values(Date.new(2021, 8, 31)).for(:started_on) }
        it { is_expected.to allow_values(Date.new(2021, 9, 1), Date.new(2021, 9, 2)).for(:started_on) }
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
      it { is_expected.to validate_inclusion_of(:number_of_terms).in_range(0..16).with_message("Terms must be between 0 and 16").on(%i[release_ect record_outcome]) }

      context "when finished_on is blank" do
        subject { FactoryBot.build(:pending_induction_submission, finished_on: nil) }

        it "validates absence of number_of_terms" do
          subject.number_of_terms = 5
          subject.valid?(:release_ect)
          expect(subject.errors[:number_of_terms]).to include("Delete the number of terms if the induction has no end date")
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
        before { pending_induction_submission.finished_on = Date.current }

        it "is valid" do
          expect(pending_induction_submission).to be_valid
        end
      end

      context "when finished_on is in the past" do
        before { pending_induction_submission.finished_on = Date.current - 1.day }

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
end
