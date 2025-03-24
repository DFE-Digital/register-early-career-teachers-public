RSpec.describe ImportJob, type: :job do
  before do
    fake_client = TRS::FakeAPIClient.new

    allow(::TRS::APIClient).to receive(:new).and_return(fake_client)

    allow(fake_client).to receive(:find_teacher).with(any_args).and_return(
      TRS::Teacher.new(
        'trn' => '1234568',
        'firstName' => 'Kirk',
        'lastName' => 'Van Houten',
        'dateOfBirth' => '1977-02-03',
        'alerts' => [
          {
            'alertType' => {
              'alertCategory' => {
                'alertCategoryId' => TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID
              }
            }
          }
        ]
      )
    )

    described_class.perform_now(pending_induction_submission_batch)
  end

  describe '#perform' do
    let(:submissions) do
      pending_induction_submission_batch.pending_induction_submissions
    end

    context 'with valid complete data' do
      include_context 'csv file', 'seeds'

      it 'creates records for all rows' do
        expect(submissions.count).to eq(14)
      end
    end

    context 'with valid partial data' do
      skip 'create fixture with gaps'
      include_context 'csv file', 'valid'

      it 'creates records for some rows' do
        expect(submissions.count).to eq(2)
      end
    end
  end
end
