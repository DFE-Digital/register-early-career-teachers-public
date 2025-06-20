RSpec.describe BatchHelper, type: :helper do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:batch) { FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body:, filename: "test.csv") }
  let(:batches) { [batch] }

  # Mock GovUK helper methods to avoid dependency issues
  before do
    allow(helper).to receive_messages(govuk_tag: '<span class="govuk-tag">test</span>', govuk_link_to: '<a href="/test">link</a>', govuk_table: '<table class="govuk-table">table</table>', govuk_summary_list: '<dl class="govuk-summary-list">summary</dl>', admin_bulk_batch_path: '/admin/bulk/batches/1')
  end

  describe "#batch_status_tag" do
    it "returns a tag for the batch status" do
      result = helper.batch_status_tag(batch)
      expect(result).to eq('<span class="govuk-tag">test</span>')
      expect(helper).to have_received(:govuk_tag).with(
        text: batch.batch_status,
        colour: 'grey'
      )
    end
  end

  describe "#admin_batch_list_table" do
    it "creates a table with batch information" do
      result = helper.admin_batch_list_table(batches)

      expect(result).to eq('<table class="govuk-table">table</table>')
      expect(helper).to have_received(:govuk_table).with(
        head: [
          'Batch ID',
          'Appropriate Body',
          'Type',
          'Status',
          'Filename',
          'Created',
          'CSV Rows',
          'Processed',
          'Errors'
        ],
        rows: [[
          '<a href="/test">link</a>',
          batch.appropriate_body.name,
          '<span class="govuk-tag">test</span>',
          '<span class="govuk-tag">test</span>',
          'test.csv',
          batch.created_at.to_fs(:govuk),
          '1',
          '0',
          '0'
        ]]
      )
    end
  end

  describe "#batch_progress_card" do
    it "creates a summary card with batch details" do
      result = helper.batch_progress_card(batch)

      expect(result).to eq('<dl class="govuk-summary-list">summary</dl>')
      expect(helper).to have_received(:govuk_summary_list).with(
        card: { title: 'Progress' },
        rows: array_including(
          { key: { text: 'Appropriate Body' }, value: { text: batch.appropriate_body.name } },
          { key: { text: 'Batch ID' }, value: { text: batch.id } },
          { key: { text: 'Number of CSV rows' }, value: { text: 1 } }
        )
      )
    end
  end

  describe "#batch_processed_data_table" do
    it "creates a table showing processed submissions" do
      result = helper.batch_processed_data_table(batch)

      expect(result).to eq('<table class="govuk-table">table</table>')
      expect(helper).to have_received(:govuk_table).with(
        caption: "Processed submissions (0 total)",
        head: ['TRN', 'Date of birth', 'Status', 'Error messages'],
        rows: []
      )
    end
  end

  describe "#batch_download_data_table" do
    it "creates a table showing submissions with errors" do
      result = helper.batch_download_data_table(batch)

      expect(result).to eq('<table class="govuk-table">table</table>')
      expect(helper).to have_received(:govuk_table).with(
        caption: "Submissions with errors (0 rows)",
        head: ['TRN', 'Date of birth', 'Error messages'],
        rows: []
      )
    end
  end

  describe "#batch_actions_induction_periods_table" do
    it "creates a table showing valid action submissions" do
      result = helper.batch_actions_induction_periods_table(batch)

      expect(result).to eq('<table class="govuk-table">table</table>')
      expect(helper).to have_received(:govuk_table).with(
        caption: "Valid action submissions (0 records)",
        head: ['TRN', 'Date of birth', 'Finish date', 'Number of terms', 'Outcome'],
        rows: []
      )
    end
  end

  describe "#batch_claims_induction_periods_table" do
    it "creates a table showing valid claim submissions" do
      result = helper.batch_claims_induction_periods_table(batch)

      expect(result).to eq('<table class="govuk-table">table</table>')
      expect(helper).to have_received(:govuk_table).with(
        caption: "Valid claim submissions (0 records)",
        head: ['TRN', 'Date of birth', 'Induction programme', 'Start date'],
        rows: []
      )
    end
  end
end
