RSpec.describe AppropriateBodies::ProcessBatch::Claim do
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
  let(:dob) { '1997-01-15' }
  let(:start_date) { (Time.zone.today - 1.week).to_s }
  let(:induction_programme) { 'FIP' }
  let(:error) { '' }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body:)
  end

  let(:submission) do
    service.pending_induction_submission_batch.pending_induction_submissions.first
  end

  let(:csv_file) do
    <<~CSV_DATA
      trn,dob,start_date,induction_programme,error
      #{trn},#{dob},#{start_date},#{induction_programme},#{error}
    CSV_DATA
  end

  before do
    allow(pending_induction_submission_batch).to receive(:csv_file).and_return(double(:csv_file, download: csv_file))
  end

  describe '#process!' do
    before do
      service.process!
    end

    it 'has no error message' do
      expect(pending_induction_submission_batch.reload.error_message).to eq '-'
      expect(submission.error_message).to eq '✅'
    end

    it 'creates a pending induction submission' do
      expect(service.pending_induction_submission_batch.pending_induction_submissions.count).to eq 1
    end

    it 'populates submission from CSV' do
      expect(submission.started_on).to eq(Date.parse(start_date))
    end

    it 'populates submission from TRS' do
      expect(submission.trn).to eq trn
      expect(submission.date_of_birth).to eq(Date.parse(dob))
      expect(submission.trs_first_name).to eq 'Kirk'
      expect(submission.trs_last_name).to eq 'Van Houten'
    end

    it 'records the teacher' do
      teacher = Teacher.first
      expect(teacher.trn).to eq trn
    end

    it 'opens induction period' do
      induction_period = InductionPeriod.first
      expect(induction_period.started_on).to eq(Date.parse(start_date))
      expect(induction_period.induction_programme).to eq('fip')
    end
  end
end
