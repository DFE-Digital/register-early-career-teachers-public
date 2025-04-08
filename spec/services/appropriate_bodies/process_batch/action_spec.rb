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
  let(:end_date) { (Time.zone.today - 1.week).to_s }
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

  let(:csv_file) do
    <<~CSV_DATA
      trn,dob,end_date,number_of_terms,objective,error
      #{trn},#{dob},#{end_date},#{number_of_terms},#{objective},#{error}
    CSV_DATA
  end

  before do
    allow(pending_induction_submission_batch).to receive(:csv_file).and_return(double(:csv_file, download: csv_file))
  end

  describe '#process!' do
    describe 'passing' do
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

      it 'has no error message' do
        expect(pending_induction_submission_batch.reload.error_message).to eq '-'
      end

      it 'creates a pending induction submission' do
        expect(service.pending_induction_submission_batch.pending_induction_submissions.count).to eq 1
      end

      it 'populates submission from CSV' do
        expect(submission.outcome).to eq 'pass'
        expect(submission.number_of_terms).to eq 3.2
        expect(submission.error_message).to eq '✅'
        expect(submission.date_of_birth).to eq(Date.parse(dob))
        expect(submission.finished_on).to eq(Date.parse(end_date))
      end

      it 'populates submission from TRS' do
        expect(submission.trn).to eq trn
        expect(submission.trs_first_name).to eq 'Kirk'
        expect(submission.trs_last_name).to eq 'Van Houten'
      end

      it 'does not closes edit induction period' do
        expect(induction_period.finished_on).not_to eq(Date.parse(end_date))
        expect(induction_period.number_of_terms).not_to eq(3.2)
        expect(induction_period.outcome).not_to eq('pass')
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
