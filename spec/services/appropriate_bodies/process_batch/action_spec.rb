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
  let(:dob) { '1997-01-15' }
  let(:end_date) { 1.week.ago.to_date.to_s }
  let(:number_of_terms) { '3.2' }
  let(:objective) { 'pass' }
  let(:error) { '' }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:teacher) do
    FactoryBot.create(:teacher, :with_corrected_name,
                      trn:,
                      trs_first_name: first_name,
                      trs_last_name: last_name)
  end

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body:)
  end

  let(:submission) do
    service.pending_induction_submission_batch.pending_induction_submissions.first
  end

  let(:csv_data) do
    <<~CSV_DATA
      trn,dob,end_date,number_of_terms,objective,error
      #{trn},#{dob},#{end_date},#{number_of_terms},#{objective},#{error}
    CSV_DATA
  end

  let(:csv_file) do
    double(:csv_file, download: csv_data, attached?: true, content_type: 'text/csv')
  end

  before do
    allow(pending_induction_submission_batch).to receive(:csv_file).and_return(csv_file)
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
        expect(submission.error_message).to eq 'Teacher Kirk Van Houten does not have an ongoing induction'
      end

      it 'clears attributes that may cause errors' do
        expect(submission.outcome).not_to eq 'pass'
        expect(submission.number_of_terms).not_to eq 3.2
        expect(submission.finished_on).not_to eq(Date.parse(end_date))
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
        induction_period.reload
      end

      it 'creates a pending induction submission' do
        expect(service.pending_induction_submission_batch.pending_induction_submissions.count).to eq 1
      end

      it 'captures no error message' do
        expect(pending_induction_submission_batch.reload.error_message).to eq '-'
        expect(submission.error_message).to eq '✅'
      end

      it 'populates submission from CSV' do
        expect(submission.outcome).to eq 'pass'
        expect(submission.number_of_terms).to eq 3.2
        expect(submission.finished_on).to eq(Date.parse(end_date))
      end

      it 'populates submission from TRS' do
        expect(submission.trn).to eq trn
        expect(submission.date_of_birth).to eq(Date.parse(dob))
        expect(submission.trs_first_name).to eq 'Kirk'
        expect(submission.trs_last_name).to eq 'Van Houten'
      end

      it 'does not closes edit induction period' do
        expect(induction_period.finished_on).not_to eq(Date.parse(end_date))
        expect(induction_period.number_of_terms).not_to eq(3.2)
        expect(induction_period.outcome).not_to eq('pass')
      end

      context 'when the number of terms has too many decimal places' do
        let(:number_of_terms) { '3.0000002' }

        it 'captures an error message' do
          expect(submission.error_message).to eq 'Number of terms Terms can only have up to 1 decimal place'
        end
      end

      context 'when the number of terms is missing' do
        let(:number_of_terms) { '' }

        it 'captures an error message' do
          expect(submission.error_message).to eq 'Number of terms Enter a number of terms'
        end
      end

      context 'when the end date is in the future' do
        let(:end_date) { 1.year.from_now.to_date.to_s }

        it 'captures an error message' do
          expect(submission.error_message).to eq 'Finished on End date cannot be in the future'
        end
      end

      context 'when the end date is missing' do
        let(:end_date) { '' }

        it 'captures an error message' do
          expect(submission.error_message).to eq 'Number of terms Delete the number of terms if the induction has no end date and Finished on Enter a finish date'
        end
      end

      context 'when the objective is not "pass", "fail" or "release"' do
        let(:objective) { 'foo' }

        it 'offers custom error message for the CSV row' do
          expect(submission.error_message).to eq "Outcome Objective must be pass, fail or release"
        end
      end

      describe '#do!' do
        before do
          service.do!
          induction_period.reload
        end

        it 'closes induction period with a pass' do
          expect(induction_period.finished_on).to eq(Date.parse(end_date))
          expect(induction_period.number_of_terms).to eq(3.2)
          expect(induction_period.outcome).to eq('pass')
        end
      end
    end
  end
end
