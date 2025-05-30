require 'rails_helper'

RSpec.describe BatchHelper, type: :helper do
  include FactoryBot::Syntax::Methods

  let(:appropriate_body) { create(:appropriate_body) }
  let(:batch) { create(:pending_induction_submission_batch, :claim, appropriate_body:) }

  describe '#batch_status_tag' do
    it 'returns a tag with the correct status and color' do
      allow(batch).to receive(:batch_status).and_return('completed')
      result = helper.batch_status_tag(batch)
      expect(result).to include('completed')
      expect(result).to include('green')
    end
  end
end
