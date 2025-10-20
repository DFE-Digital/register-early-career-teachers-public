RSpec.describe AppropriateBodies::ProcessBatch::Claim do
  subject(:service) do
    described_class.new(pending_induction_submission_batch:, author:)
  end

  let(:author) do
    FactoryBot.create(:appropriate_body_user,
      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id)
  end
  let(:trn) { "1000890" }
  let(:date_of_birth) { "1997-03-15" }
  let(:started_on) { 1.week.ago.to_date.to_s }
  let(:training_programme) { "provider-led" }
  let(:error) { nil }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim,
      appropriate_body:,
      data: [
        {trn:, date_of_birth:, started_on:, training_programme:, error:}
      ])
  end

  let(:submissions) do
    service.pending_induction_submission_batch.pending_induction_submissions
  end

  let(:submission) { submissions.first }
  let(:teacher) { submission.teacher }
  let(:induction_period) { teacher.induction_periods.first }

  describe "#process!" do
    include_context "test trs api client that finds teacher with specific induction status", "InProgress"

    before { service.process! }

    it "has no error message" do
      expect(pending_induction_submission_batch.reload.error_message).to be_nil
      expect(submission.error_messages).to be_empty
    end

    it "creates a pending induction submission" do
      expect(submissions.count).to eq 1
    end

    it "populates submission from CSV" do
      expect(submission.started_on).to eq(Date.parse(started_on))
    end

    it "populates submission from TRS" do
      expect(submission.trn).to eq trn
      expect(submission.date_of_birth).to eq(Date.parse(date_of_birth))
      expect(submission.trs_first_name).to eq "Kirk"
      expect(submission.trs_last_name).to eq "Van Houten"
    end

    context "when the ECT has been released from a previous induction claim" do
      include_context "test trs api client that finds teacher with specific induction status", "InProgress"

      let(:started_on) { 1.day.ago.to_date.to_s }

      let(:teacher) { FactoryBot.create(:teacher, trn:) }

      before do
        FactoryBot.create(:induction_period, teacher:,
          appropriate_body:,
          started_on: 30.days.ago.to_date,
          finished_on: 15.days.ago.to_date)
        service.process!
      end

      it "has no error message" do
        expect(pending_induction_submission_batch.reload.error_message).to be_nil
        expect(submission.error_messages).to be_empty
      end
    end

    describe "formatting checks" do
      before { service.process! }

      context "when the TRN is missing" do
        let(:trn) { nil }
        let(:teacher) {}

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Fill in the blanks on this row",
            "Enter a valid TRN using 7 digits"
          ]
        end
      end

      context "when the date of birth is missing" do
        let(:date_of_birth) { nil }

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Fill in the blanks on this row",
            "Dates must be in the format YYYY-MM-DD",
            "Date of birth must be a real date and the teacher must be between 18 and 100 years old"
          ]
        end
      end

      context "when the date of birth is unrealistic" do
        let(:date_of_birth) { 100.years.ago.to_date.to_s }

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Date of birth must be a real date and the teacher must be between 18 and 100 years old"
          ]
        end
      end

      context "when the date of birth is in the future" do
        let(:date_of_birth) { 1.year.from_now.to_date.to_s }

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Date of birth must be a real date and the teacher must be between 18 and 100 years old"
          ]
        end
      end

      context "when the start date is missing" do
        let(:started_on) { nil }

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Fill in the blanks on this row",
            "Dates must be in the format YYYY-MM-DD",
            "Dates cannot be in the future",
            "Induction start date must be after 1 September 2021"
          ]
        end
      end

      context "when the start date predates the service rollout" do
        let(:started_on) { 7.years.ago.to_date.to_s }

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Induction start date must be after 1 September 2021"
          ]
        end
      end

      context "when the training programme is missing" do
        let(:training_programme) { nil }

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Fill in the blanks on this row",
            "Induction programme type must be school-led or provider-led"
          ]
        end
      end

      context "when the TRN contains additional padding" do
        let(:trn) { "  1234567  " }

        it "passes validation" do
          expect(submission.error_messages).not_to eq ["Enter a valid TRN using 7 digits"]
        end

        it "uses a sanitised version to bypass database restrictions" do
          expect(submission.trn).to eq "1234567"
        end
      end

      context "when the TRN contains additional non-digits" do
        let(:trn) { "1234567L" }

        it "captures an error message" do
          expect(submission.error_messages).to eq ["Enter a valid TRN using 7 digits"]
        end

        it "uses a sanitised version to bypass database restrictions" do
          expect(submission.trn).to eq "1234567"
        end
      end

      context "when the TRN contains too many digits" do
        let(:trn) { "1 2 3 4 5 6 7 8 9" }

        it "captures an error message" do
          expect(submission.error_messages).to eq ["Enter a valid TRN using 7 digits"]
        end

        it "uses a sanitised version to bypass database restrictions" do
          expect(submission.trn).to eq "1234567"
        end
      end

      context "when the TRN is missing digits" do
        let(:trn) { "0004" }

        it "captures an error message" do
          expect(submission.error_messages).to eq ["Enter a valid TRN using 7 digits"]
        end
      end

      context "when the TRN contains other characters" do
        let(:trn) { "123456L" }

        it "captures an error message" do
          expect(submission.error_messages).to eq ["Enter a valid TRN using 7 digits"]
        end
      end

      context "when the date of birth is not ISO8601" do
        let(:date_of_birth) { "30/06/1981" }

        it "captures an error message" do
          expect(submission.error_messages).to eq ["Dates must be in the format YYYY-MM-DD"]
        end
      end

      context "when the start date is not ISO8601" do
        let(:started_on) { "30/06/2022" }

        it "captures an error message" do
          expect(submission.error_messages).to eq ["Dates must be in the format YYYY-MM-DD"]
        end
      end

      context "when the training programme is not recognised" do
        let(:training_programme) { "foo" }

        it "captures an error message" do
          expect(submission.error_messages).to eq ["Induction programme type must be school-led or provider-led"]
        end
      end

      context "when the training programme is capitalised" do
        let(:training_programme) { "SCHOOL-LED" }

        it "passes validation" do
          expect(submission.error_messages).not_to eq ["Induction programme type must be school-led or provider-led"]
        end
      end

      context "when multiple cells are invalid" do
        let(:teacher) {}
        let(:trn) { "0004" }
        let(:date_of_birth) { "30/06/1981" }
        let(:training_programme) { "foo" }
        let(:started_on) { nil }

        it "captures an error message" do
          expect(submission.error_messages).to eq [
            "Fill in the blanks on this row",
            "Enter a valid TRN using 7 digits",
            "Dates must be in the format YYYY-MM-DD",
            "Dates cannot be in the future",
            "Induction start date must be after 1 September 2021",
            "Induction programme type must be school-led or provider-led"
          ]
        end
      end
    end

    describe "#complete!" do
      it "enqueues a job to complete the submission" do
        expect { service.complete! }.to have_enqueued_job(AppropriateBodies::ProcessBatch::RegisterECTJob).with(
          submission.id,
          author.email,
          author.name
        )
      end
    end
  end

  context "when the TRN is not found" do
    include_context "test trs api client that finds nothing"

    before { service.process! }

    it "does not create a teacher" do
      expect(teacher).to be_nil
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["TRN and date of birth do not match"] }
    end
  end

  context "when the ECT is prohibited" do
    include_context "test trs api client that finds teacher prohibited from teaching"

    before { service.process! }

    it "does not create a teacher" do
      expect(teacher).to be_nil
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten is prohibited from teaching"] }
    end
  end

  context "when the ECT does not have QTS awarded" do
    include_context "test trs api client that finds teacher without QTS"

    before { service.process! }

    it "does not create a teacher" do
      expect(teacher).to be_nil
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten does not have their qualified teacher status (QTS)"] }
    end
  end

  context "when the ECT has passed" do
    include_context "test trs api client that finds teacher with specific induction status", "Passed"

    before { service.process! }

    it "does not create a teacher" do
      expect(teacher).to be_nil
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten has already passed their induction"] }
    end
  end

  context "when the ECT has failed" do
    include_context "test trs api client that finds teacher with specific induction status", "Failed"

    before { service.process! }

    it "does not create a teacher" do
      expect(teacher).to be_nil
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten has already failed their induction"] }
    end
  end

  context "when the ECT is exempt" do
    include_context "test trs api client that finds teacher with specific induction status", "Exempt"

    before { service.process! }

    it "does not create a teacher" do
      expect(teacher).to be_nil
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten is exempt from completing their induction"] }
    end
  end

  context "when the submission overlaps an earlier induction period" do
    include_context "test trs api client that finds teacher with specific induction status", "InProgress"

    let(:started_on) { 15.days.ago.to_date.to_s }

    let(:teacher) { FactoryBot.create(:teacher, trn:) }

    before do
      FactoryBot.create(:induction_period, teacher:,
        started_on: 30.days.ago.to_date,
        finished_on: 1.day.ago.to_date)
      service.process!
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Induction start date must not overlap with any other induction periods"] }
    end
  end

  context "start date before QTS" do
    include_context "test trs api client that finds teacher with specific induction status", "InProgress"

    let(:qts_date) { 3.years.ago.to_date }
    let(:started_on) { (qts_date - 1.day).to_s }

    before do
      service.process!
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Induction start date must not be before QTS date (#{qts_date.to_fs(:govuk)})"] }
    end
  end

  context "when the ECT has already passed" do
    include_context "test trs api client that finds teacher that has passed their induction"

    let(:teacher) { FactoryBot.create(:teacher, trn:) }

    before do
      FactoryBot.create(:induction_period, :pass, teacher:, appropriate_body:)
      service.process!
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten has already passed their induction"] }
    end
  end

  context "when the ECT has already failed" do
    include_context "test trs api client that finds teacher that has failed their induction"

    let(:teacher) { FactoryBot.create(:teacher, trn:) }

    before do
      FactoryBot.create(:induction_period, :fail, teacher:, appropriate_body:)
      service.process!
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten has already failed their induction"] }
    end
  end

  context "when the ECT is already claimed by another body" do
    include_context "test trs api client that finds teacher with specific induction status", "InProgress"

    let(:other_body) { FactoryBot.create(:appropriate_body, name: "Acme") }
    let(:teacher) { FactoryBot.create(:teacher, trn:) }

    before do
      FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body: other_body)
      service.process!
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Kirk Van Houten is already claimed by another appropriate body (Acme)"] }
    end
  end

  context "when induction programme is unknown" do
    include_context "test trs api client that finds teacher with specific induction status", "InProgress"

    let(:training_programme) { "foo" }

    before { service.process! }

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Induction programme type must be school-led or provider-led"] }
    end
  end

  context "when start date is in the future" do
    include_context "test trs api client that finds teacher with specific induction status", "InProgress"

    let(:started_on) { 1.year.from_now.to_date.to_s }

    before { service.process! }

    it "does not create a teacher" do
      expect(teacher).to be_nil
    end

    describe "batch error message" do
      subject { pending_induction_submission_batch.error_message }

      it { is_expected.to be_nil }
    end

    describe "submission error messages" do
      subject { submission.error_messages }

      it { is_expected.to eq ["Dates cannot be in the future"] }
    end
  end
end
