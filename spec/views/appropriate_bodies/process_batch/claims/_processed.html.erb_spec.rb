require 'rails_helper'

RSpec.describe 'appropriate_bodies/process_batch/claims/_processed.html.erb', type: :view do
  include FactoryBot::Syntax::Methods

  let(:appropriate_body) { create(:appropriate_body) }
  let(:batch) { create(:pending_induction_submission_batch, :claim, appropriate_body:, filename: 'test.csv') }

  before do
    # Mock the data method to return some rows
    allow(batch).to receive(:data).and_return([{}, {}, {}]) # 3 total records
    assign(:batch, batch)
  end

  context 'when all records have errors' do
    before do
      create(:pending_induction_submission,
             pending_induction_submission_batch: batch,
             appropriate_body:,
             error_messages: ['TRN not found'])
      create(:pending_induction_submission,
             pending_induction_submission_batch: batch,
             appropriate_body:,
             error_messages: ['Invalid date'])
    end

    it 'displays error summary' do
      render partial: 'appropriate_bodies/process_batch/claims/processed', locals: { batch: }

      expect(rendered).to include('CSV file summary')
      expect(rendered).to include('2 ECTs with errors')
      expect(rendered).to include('Download CSV with error messages included')
    end
  end

  context 'when there are successful claims' do
    before do
      create(:pending_induction_submission,
             pending_induction_submission_batch: batch,
             appropriate_body:,
             induction_programme: 'fip',
             error_messages: [])
      create(:pending_induction_submission,
             pending_induction_submission_batch: batch,
             appropriate_body:,
             induction_programme: 'cip',
             error_messages: [])
      create(:pending_induction_submission,
             pending_induction_submission_batch: batch,
             appropriate_body:,
             induction_programme: 'fip',
             error_messages: ['Some error'])
    end

    it 'displays success summary with simple text' do
      render partial: 'appropriate_bodies/process_batch/claims/processed', locals: { batch: }

      expect(rendered).to include('CSV file summary')
      expect(rendered).to include('had a total 3 ECT records in one year claims')
      expect(rendered).to include('You have 2 ECTs without errors')
      expect(rendered).to include('You had 1 ECT with errors which were not processed')
    end
  end
end
