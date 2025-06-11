RSpec.describe AppropriateBodies::ProcessBatch::Action do
  subject(:service) do
    described_class.new(pending_induction_submission_batch:, author:)
  end

  include_context 'fake trs api client'

  let(:author) do
    Sessions::Users::AppropriateBodyUser.new(
      name: 'A user',
      email: 'ab_user@something.org',
      dfe_sign_in_user_id: SecureRandom.uuid,
      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id
    )
  end
  let(:trn) { '1000890' }
  let(:first_name) { 'Terry' }
  let(:last_name) { 'Wogan' }
  let(:date_of_birth) { '1997-01-15' }
  let(:finished_on) { 1.week.ago.to_date.to_s }
  let(:number_of_terms) { '3.2' }
  let(:outcome) { 'pass' }
  let(:error) { '' }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:teacher) do
    FactoryBot.create(:teacher, :with_corrected_name,
                      trn:,
                      trs_first_name: first_name,
                      trs_last_name: last_name)
  end

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action,
                      appropriate_body:,
                      data: [
                        { trn:, date_of_birth:, finished_on:, number_of_terms:, outcome:, error: }
                      ])
  end

  let(:submission) do
    service.pending_induction_submission_batch.pending_induction_submissions.first
  end

  describe '#process!' do
    context 'without an ongoing induction' do
      before do
        teacher
        service.process!
      end

      it 'creates a pending induction submission' do
        expect(service.pending_induction_submission_batch.pending_induction_submissions.count).to eq 1
      end

      it 'captures error message' do
        expect(submission.error_messages).to eq ['Kirk Van Houten does not have an open induction']
      end

      it 'clears attributes that may cause errors' do
        expect(submission.outcome).not_to eq 'pass'
        expect(submission.number_of_terms).not_to eq 3.2
        expect(submission.finished_on).not_to eq(Date.parse(finished_on))
      end
    end

    describe 'formatting checks' do
      before do
        service.process!
      end

      context 'when the TRN is missing' do
        let(:trn) { '' }
        let(:teacher) {}

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Fill in the blanks on this row',
            'Enter a valid TRN using 7 digits'
          ]
        end
      end

      context 'when the date of birth is missing' do
        let(:date_of_birth) { '' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Fill in the blanks on this row',
            'Dates must be in the format YYYY-MM-DD'
          ]
        end
      end

      context 'when the date of birth is unrealistic' do
        let(:date_of_birth) { 100.years.ago }

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Date of birth must be a real date and the teacher must be between 18 and 100 years old',
          ]
        end
      end

      context 'when the date of birth is in the future' do
        let(:date_of_birth) { 1.year.from_now }

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Date of birth must be a real date and the teacher must be between 18 and 100 years old',
          ]
        end
      end

      context 'when the number of terms is missing' do
        let(:number_of_terms) { '' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Fill in the blanks on this row',
            'Enter number of terms between 0 and 16 using up to one decimal place'
          ]
        end
      end

      context 'when the end date is missing' do
        let(:finished_on) { '' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Fill in the blanks on this row',
            'Dates must be in the format YYYY-MM-DD'
          ]
        end
      end

      context 'when the outcome is missing' do
        let(:outcome) { '' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Fill in the blanks on this row',
            'Outcome must be either pass, fail or release'
          ]
        end
      end

      context 'when the TRN contains additional padding' do
        let(:trn) { '  1234567  ' }

        it 'passes validation' do
          expect(submission.error_messages).not_to eq ['Enter a valid TRN using 7 digits']
        end

        it 'uses a sanitised version to bypass database restrictions' do
          expect(submission.trn).to eq '1234567'
        end
      end

      context 'when the TRN contains additional non-digits' do
        let(:trn) { '1234567L' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Enter a valid TRN using 7 digits']
        end

        it 'uses a sanitised version to bypass database restrictions' do
          expect(submission.trn).to eq '1234567'
        end
      end

      context 'when the TRN contains too many digits' do
        let(:trn) { '1 2 3 4 5 6 7 8 9' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Enter a valid TRN using 7 digits']
        end

        it 'uses a sanitised version to bypass database restrictions' do
          expect(submission.trn).to eq '1234567'
        end
      end

      context 'when the TRN is missing digits' do
        let(:trn) { '0004' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Enter a valid TRN using 7 digits']
        end
      end

      context 'when the TRN contains other characters' do
        let(:trn) { '123456L' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Enter a valid TRN using 7 digits']
        end
      end

      context 'when the date of birth is not ISO8601' do
        let(:date_of_birth) { '30/06/1981' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Dates must be in the format YYYY-MM-DD']
        end
      end

      context 'when the end date is not ISO8601' do
        let(:finished_on) { '30/06/1981' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Dates must be in the format YYYY-MM-DD']
        end
      end

      context 'when the outcome is not recognised' do
        let(:outcome) { 'foo' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Outcome must be either pass, fail or release']
        end
      end

      context 'when the outcome is capitalised' do
        let(:outcome) { 'PASS' }

        it 'passes validation' do
          expect(submission.error_messages).not_to eq ['Outcome must be either pass, fail or release']
        end
      end

      context 'when the outcome is reworded' do
        let(:outcome) { 'Failure' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Outcome must be either pass, fail or release']
        end
      end

      context 'when the number of terms exceeds 1 decimal place' do
        let(:number_of_terms) { '12.06' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Enter number of terms between 0 and 16 using up to one decimal place']
        end
      end

      context 'when the number of terms exceeds 16' do
        let(:number_of_terms) { '17' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Enter number of terms between 0 and 16 using up to one decimal place']
        end
      end

      context 'when multiple cells are invalid' do
        let(:teacher) {}
        let(:trn) { '0004' }
        let(:date_of_birth) { '30/06/1981' }
        let(:outcome) { 'foo' }
        let(:number_of_terms) { '12.06' }
        let(:finished_on) { '' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq [
            'Fill in the blanks on this row',
            'Dates must be in the format YYYY-MM-DD',
            'Enter a valid TRN using 7 digits',
            'Outcome must be either pass, fail or release',
            'Enter number of terms between 0 and 16 using up to one decimal place'
          ]
        end
      end
    end

    context 'with an ongoing induction at another Appropriate Body' do
      let(:other_body) { FactoryBot.create(:appropriate_body) }

      let!(:induction_period) do
        FactoryBot.create(:induction_period, :active,
                          appropriate_body: other_body,
                          teacher:,
                          started_on: '2024-1-1')
      end

      before do
        service.process!
      end

      it 'captures error message' do
        expect(submission.error_messages).to eq ['Kirk Van Houten is completing their induction with another appropriate body']
      end
    end

    context 'with an ongoing induction' do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :active,
                          appropriate_body:,
                          teacher:,
                          started_on: '2024-1-1')
      end

      before do
        service.process!
      end

      it 'creates a pending induction submission' do
        expect(service.pending_induction_submission_batch.pending_induction_submissions.count).to eq 1
      end

      it 'captures no error message' do
        expect(pending_induction_submission_batch.reload.error_message).to be_nil # singular batch error
        expect(submission.error_messages).to be_empty
      end

      it 'populates submission from CSV' do
        expect(submission.outcome).to eq 'pass'
        expect(submission.number_of_terms).to eq 3.2
        expect(submission.finished_on).to eq(Date.parse(finished_on))
      end

      it 'populates submission from TRS' do
        expect(submission.trn).to eq trn
        expect(submission.date_of_birth).to eq(Date.parse(date_of_birth))
        expect(submission.trs_first_name).to eq 'Kirk'
        expect(submission.trs_last_name).to eq 'Van Houten'
      end

      it 'does not closes edit induction period' do
        expect(induction_period.finished_on).not_to eq(Date.parse(finished_on))
        expect(induction_period.number_of_terms).not_to eq(3.2)
        expect(induction_period.outcome).not_to eq('pass')
      end

      context 'when the TRN is missing' do
        let(:error) { '2nd attempt from downloaded CSV with errors' }

        it 'replaces errors' do
          expect(submission.error_messages).to be_empty
        end
      end

      context 'when the end date is in the future' do
        let(:finished_on) { 1.year.from_now.to_date.to_s }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['End date cannot be in the future']
        end
      end

      context 'when the end date is before the start date' do
        let(:finished_on) { '2000-01-01' }

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Induction end date must be after the induction start date (1 January 2024)']
        end
      end

      context 'with a completed induction' do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, :pass,
                            appropriate_body:,
                            teacher:)
        end

        before do
          service.process!
        end

        it 'captures an error message' do
          expect(submission.error_messages).to eq ['Kirk Van Houten has already completed their induction']
        end
      end

      describe '#complete!' do
        before do
          allow(Events::Record).to receive(:record_teacher_passes_induction_event!).and_call_original

          service.complete!

          induction_period.reload
        end

        it 'closes induction period with a pass' do
          expect(induction_period.finished_on).to eq(Date.parse(finished_on))
          expect(induction_period.number_of_terms).to eq(3.2)
          expect(induction_period.outcome).to eq('pass')
        end

        it 'creates events owned by the author' do
          expect(Events::Record).to have_received(:record_teacher_passes_induction_event!).with(
            appropriate_body:,
            teacher:,
            induction_period:,
            author:
          )
        end
      end
    end
  end
end
