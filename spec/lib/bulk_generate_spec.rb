RSpec.describe BulkGenerate do
  include_context 'test trs api client'

  let(:bulk_generate) { described_class.new }

  describe 'defaults' do
    it { expect(bulk_generate.trs).to be true }
    it { expect(bulk_generate.period_min_interval).to eq(60) }
    it { expect(bulk_generate.claim_filename).to eq('tmp/bulk-claim.csv') }
    it { expect(bulk_generate.action_filename).to eq('tmp/bulk-action.csv') }
    it { expect(bulk_generate.dataset).to be_a(Pathname) }
    it { expect(bulk_generate.claim_headers).to eq(::BatchRows::CLAIM_CSV_HEADINGS.values) }
    it { expect(bulk_generate.action_headers).to eq(::BatchRows::ACTION_CSV_HEADINGS.values) }
  end

  it 'loads TRNS' do
    expect(bulk_generate.trns.size).to eq(1_525)
    expect(bulk_generate.trns.first).to eq(%w[1000522 1986-03-02])
  end

  describe '#call' do
    context 'when called' do
      let(:bulk_generate) do
        described_class.new(
          period_min_interval: 1,
          claim_csv_file: 'tmp/bulk-claim-test.csv',
          action_csv_file: 'tmp/bulk-action-test.csv'
        )
      end

      it 'calls the API client' do
        allow(bulk_generate.api_client).to receive(:find_teacher).and_return(
          OpenStruct.new(present: OpenStruct.new(trs_induction_status: 'TRS status'))
        )
        expect(bulk_generate.call).to be_nil
        expect(bulk_generate.api_client).to have_received(:find_teacher).exactly(1_525).times
        expect(bulk_generate.claim_rows.first[4]).to eq('TRS status')
        expect(bulk_generate.action_rows.first[5]).to eq('TRS status')
      end

      it 'generates rows that match headers' do
        expect(bulk_generate.claim_rows.first.size).to eq(bulk_generate.claim_headers.size)
        expect(bulk_generate.action_rows.first.size).to eq(bulk_generate.action_headers.size)
      end

      it 'exports the claim and action CSVs' do
        bulk_generate.call
        expect(File.exist?(bulk_generate.claim_filename)).to be true
        expect(File.exist?(bulk_generate.action_filename)).to be true
      end

      it 'selects induction period dates that do not overlap' do
        expect(bulk_generate.claim_rows.first[3]).to eq(2.days.ago.to_date)
        expect(bulk_generate.action_rows.first[2]).to eq(1.day.ago.to_date)
      end
    end
  end
end
