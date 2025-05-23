RSpec.describe BatchRows do
  let(:dummy_claim) { DummyBatchClaim.new }
  let(:dummy_action) { DummyBatchAction.new }
  let(:dummy_unknown) { DummyBatchUnknown.new }

  describe '.build_row_class' do
    subject(:row_class) { described_class.build_row_class(%i[foo bar baz]) }

    it 'errors if the wrong attributes are used' do
      expect { row_class.new }.to raise_error('missing keywords: :foo, :bar, :baz')
    end

    it 'creates an enumerable Data class to encapsulate CSV row cells' do
      row = row_class.new(foo: 'foo', bar: 'bar', baz: 'baz')
      expect(row).to be_a(row_class)
      expect(row).to be_a(Enumerable)
      expect(row.to_a).to eq(%w[foo bar baz])
      expect(row).to respond_to(:foo)
      expect(row).not_to respond_to(:buz)
    end

    it 'string encodes values' do
      row = row_class.new(foo: 'André', bar: 'Zoë', baz: 'Ştefan')
      expect(row.to_a).to eq(%w[André Zoë Ştefan])
    end
  end

  describe '#row_headings' do
    it { expect(dummy_claim.row_headings).to eql(BatchRows::CLAIM_CSV_HEADINGS) }
    it { expect(dummy_action.row_headings).to eql(BatchRows::ACTION_CSV_HEADINGS) }

    it { expect(dummy_claim.row_headings.values).to eql(["TRN", "Date of birth", "Induction programme", "Induction period start date", "Error message"]) }
    it { expect(dummy_action.row_headings.values).to eql(["TRN", "Date of birth", "Induction period end date", "Number of terms", "Outcome", "Error message"]) }

    it { expect(dummy_unknown.row_headings).to be_nil }
  end

  describe '#rows' do
    context 'when the batch type is a "claim"' do
      it { expect(dummy_claim.rows).to be_an(Enumerator::Lazy) }
      it { expect(dummy_claim.rows.first).to be_a(BatchRows::ClaimRow) }
    end

    context 'when the batch type is an "action"' do
      it { expect(dummy_action.rows).to be_an(Enumerator::Lazy) }
      it { expect(dummy_action.rows.first).to be_a(BatchRows::ActionRow) }
    end

    context 'when the batch type cannot be determined' do
      it { expect(dummy_unknown.rows).to be_an(Enumerator::Lazy) }
      it { expect { dummy_unknown.rows.first }.to raise_error(NoMethodError) }
    end

    context 'when parsed CSV data omits the optional error column' do
      before do
        allow(dummy_claim).to receive(:data).and_return([{ trn: '1234567', date_of_birth: '1981-06-30', induction_programme: 'fip', started_on: '2025-01-30' }])
        allow(dummy_action).to receive(:data).and_return([{ trn: '1234567', date_of_birth: '1981-06-30', number_of_terms: '0.5', finished_on: '2025-01-30', outcome: 'pass' }])
      end

      it { expect(dummy_claim.rows).to be_an(Enumerator::Lazy) }
      it { expect(dummy_claim.rows.first).to be_a(BatchRows::ClaimRow) }

      it { expect(dummy_action.rows).to be_an(Enumerator::Lazy) }
      it { expect(dummy_action.rows.first).to be_a(BatchRows::ActionRow) }
    end

    context 'when parsed CSV data contains missing or blank cells' do
      before do
        allow(dummy_action).to receive(:data).and_return([{ trn: '1234567', date_of_birth: nil, outcome: '' }])
      end

      it 'does not raise an error' do
        expect(dummy_action.rows).to be_an(Enumerator::Lazy)
      end

      it 'all omitted attributes return nil' do
        expect(dummy_action.rows.first.trn).to eq('1234567')
        expect(dummy_action.rows.first.date_of_birth).to be_nil
        expect(dummy_action.rows.first.finished_on).to be_nil
        expect(dummy_action.rows.first.number_of_terms).to be_nil
        expect(dummy_action.rows.first.outcome).to be_empty
        expect(dummy_action.rows.first.error).to be_nil
      end
    end
  end
end

class DummyBatchClaim < OpenStruct
  include BatchRows

  def claim? = true
  def action? = false
  def data = [{ trn: '1234567', date_of_birth: '1981-06-30', induction_programme: 'fip', started_on: '2025-01-30', error: '' }]
end

class DummyBatchAction < OpenStruct
  include BatchRows

  def claim? = false
  def action? = true
  def data = [{ trn: '1234567', date_of_birth: '1981-06-30', number_of_terms: '0.5', finished_on: '2025-01-30', outcome: 'pass', error: '' }]
end

class DummyBatchUnknown < OpenStruct
  include BatchRows

  def claim? = nil
  def action? = nil
  def data = [{ foo: 'bar' }]
end
