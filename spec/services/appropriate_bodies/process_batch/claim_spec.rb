RSpec.describe AppropriateBodies::ProcessBatch::Claim do
  subject(:service) do
    described_class.new(pending_induction_submission_batch:, author:)
  end

  let(:author) do
    Sessions::Users::AppropriateBodyUser.new(
      name: 'A user',
      email: 'ab_user@something.org',
      dfe_sign_in_user_id: SecureRandom.uuid,
      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id
    )
  end
  let(:trn) { '1000890' }
  let(:date_of_birth) { '1997-03-15' }
  let(:started_on) { 1.week.ago.to_date.to_s }
  let(:induction_programme) { 'FIP' }
  let(:error) { '' }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:pending_induction_submission_batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim,
                      appropriate_body:,
                      data: [
                        { trn:, date_of_birth:, started_on:, induction_programme:, error: }
                      ])
  end

  let(:submissions) do
    service.pending_induction_submission_batch.pending_induction_submissions
  end

  let(:submission) { submissions.first }
  let(:teacher) { submission.teacher }
  let(:induction_period) { teacher.induction_periods.first }

  describe '#process!' do
    context 'when happy' do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

      before { service.process! }

      it 'has no error message' do
        expect(pending_induction_submission_batch.reload.error_message).to be_nil
        expect(submission.error_messages).to be_empty
      end

      it 'creates a pending induction submission' do
        expect(submissions.count).to eq 1
      end

      it 'populates submission from CSV' do
        expect(submission.started_on).to eq(Date.parse(started_on))
      end

      it 'populates submission from TRS' do
        expect(submission.trn).to eq trn
        expect(submission.date_of_birth).to eq(Date.parse(date_of_birth))
        expect(submission.trs_first_name).to eq 'Kirk'
        expect(submission.trs_last_name).to eq 'Van Houten'
      end

      describe '#complete!' do
        before do
          allow(Events::Record).to receive(:record_induction_period_opened_event!).and_call_original
          service.complete!
        end

        it 'records the teacher' do
          expect(teacher.trn).to eq trn
          expect(teacher.trs_first_name).to eq 'Kirk'
          expect(teacher.trs_last_name).to eq 'Van Houten'
        end

        it 'opens induction period' do
          expect(induction_period.started_on).to eq(Date.parse(started_on))
          expect(induction_period.finished_on).to be_nil
          expect(induction_period.outcome).to be_nil
          expect(induction_period.induction_programme).to eq('fip')
        end

        it 'creates events owned by the author' do
          expect(Events::Record).to have_received(:record_induction_period_opened_event!).with(
            appropriate_body:,
            teacher:,
            induction_period:,
            author:,
            modifications: {}
          )
        end
      end
    end

    context 'when TRS induction status is unknown' do
      include_context 'fake trs api client'

      before { service.process! }

      it 'does not create a teacher' do
        expect(teacher).to be_nil
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['TRS Induction Status is not known'] }
      end
    end

    context 'when the TRN is not found' do
      include_context 'fake trs api client that finds nothing'

      before { service.process! }

      it 'does not create a teacher' do
        expect(teacher).to be_nil
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['TRN and date of birth do not match'] }
      end
    end

    context 'when the ECT is prohibited' do
      include_context 'fake trs api client that finds teacher prohibited from teaching'

      before { service.process! }

      it 'does not create a teacher' do
        expect(teacher).to be_nil
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['Kirk Van Houten is prohibited from teaching'] }
      end
    end

    context 'when the ECT does not have QTS awarded' do
      include_context 'fake trs api client that finds teacher without QTS'

      before { service.process! }

      it 'does not create a teacher' do
        expect(teacher).to be_nil
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['Kirk Van Houten does not have their qualified teacher status (QTS)'] }
      end
    end

    context 'when the ECT is already claimed' do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

      let(:teacher) { FactoryBot.create(:teacher, trn:) }

      before do
        FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:)
        service.process!
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['Kirk Van Houten is already claimed by your appropriate body'] }
      end
    end

    context 'when the ECT has already passed' do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

      let(:teacher) { FactoryBot.create(:teacher, trn:, trs_first_name: 'Luann', trs_last_name: 'Van Houten') }

      before do
        FactoryBot.create(:induction_period, :pass, teacher:, appropriate_body:)
        service.process!
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['Luann Van Houten has already passed their induction'] }
      end
    end

    context 'when the ECT has already failed' do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

      let(:teacher) { FactoryBot.create(:teacher, trn:, trs_first_name: 'Luann', trs_last_name: 'Van Houten') }

      before do
        FactoryBot.create(:induction_period, :fail, teacher:, appropriate_body:)
        service.process!
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['Luann Van Houten has already failed their induction'] }
      end
    end

    context 'when the ECT is already claimed by another body' do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

      let(:other_body) { FactoryBot.create(:appropriate_body) }
      let(:teacher) { FactoryBot.create(:teacher, trn:) }

      before do
        FactoryBot.create(:induction_period, :active, teacher:, appropriate_body: other_body)
        service.process!
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['Kirk Van Houten is already claimed by another appropriate body'] }
      end
    end

    context 'when induction programme is unknown' do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

      let(:induction_programme) { 'foo' }

      before { service.process! }

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        # it { is_expected.to eq ['Induction programme type must be school-led or provider-led'] }
        it { is_expected.to eq ['Induction programme type must be DIY, FIP or CIP'] }
      end
    end

    context 'when start date is in the future' do
      include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

      let(:started_on) { 1.year.from_now.to_date.to_s }

      before { service.process! }

      it 'does not create a teacher' do
        expect(teacher).to be_nil
      end

      describe 'batch error message' do
        subject { pending_induction_submission_batch.error_message }

        it { is_expected.to be_nil }
      end

      describe 'submission error messages' do
        subject { submission.error_messages }

        it { is_expected.to eq ['Start date cannot be in the future'] }
      end
    end
  end
end
