RSpec.describe BatchHelper, type: :helper do
  include GovukVisuallyHiddenHelper
  include GovukLinkHelper
  include GovukListHelper
  include GovukComponentsHelper

  describe "#batch_list_table" do
    subject(:table) { batch_list_table(batches) }

    let(:batches) do
      [
        FactoryBot.create(:pending_induction_submission_batch, :claim, :completed),
        FactoryBot.create(:pending_induction_submission_batch, :claim, :processed),
        FactoryBot.create(:pending_induction_submission_batch, :claim, :processing)
      ]
    end

    it 'returns a table with batch details' do
      expect(subject).to have_selector('table tr', count: 4)
      expect(subject).to have_selector('th', text: 'Reference')
      expect(subject).to have_selector('th', text: 'File name')
      expect(subject).to have_selector('th', text: 'Status')
      expect(subject).to have_selector('th', text: 'Action')

      expect(subject).to have_selector('td', text: 'View', count: 3)
      expect(subject).to have_selector('td', text: 'Completed')
      expect(subject).to have_selector('td', text: 'Processed')
      expect(subject).to have_selector('td', text: 'Processing')
    end
  end

  describe "#batch_example_claim" do
    it do
      expect(batch_example_claim).to have_text('Your file needs to look like this example')
      expect(batch_example_claim).to have_selector('table tr', count: 4)
      expect(batch_example_claim).to have_selector('th', text: 'TRN')
      expect(batch_example_claim).to have_selector('th', text: 'Date of birth')
      expect(batch_example_claim).to have_selector('th', text: 'Induction programme')
      expect(batch_example_claim).to have_selector('th', text: 'Induction period start date')

      expect(batch_example_claim).not_to have_selector('th', text: 'Error message')
    end
  end

  describe "#batch_example_action" do
    it do
      expect(batch_example_action).to have_text('Your file needs to look like this example')
      expect(batch_example_action).to have_selector('table tr', count: 4)
      expect(batch_example_action).to have_selector('th', text: 'TRN')
      expect(batch_example_action).to have_selector('th', text: 'Date of birth')
      expect(batch_example_action).to have_selector('th', text: 'Induction period end date')
      expect(batch_example_action).to have_selector('th', text: 'Number of terms')
      expect(batch_example_action).to have_selector('th', text: 'Outcome')

      expect(batch_example_action).not_to have_selector('th', text: 'Error message')
    end
  end

  context "with a single batch" do
    let(:batch) { FactoryBot.create(:pending_induction_submission_batch, :action, :completed) }

    describe "#batch_status_tag" do
      it do
        expect(batch_status_tag(batch)).to have_selector('strong', class: 'govuk-tag--green', text: 'Completed')
      end
    end

    describe "#batch_type_tag" do
      it do
        expect(batch_type_tag(batch)).to have_selector('strong', class: 'govuk-tag--purple', text: 'Action')
      end
    end

    describe "#batch_link" do
      it do
        expect(batch_link(batch)).to have_link('View', href: ab_batch_action_path(batch))
      end
    end

    describe "#batch_action_summary" do
      it do
        expect(batch_action_summary(batch)).to have_text('0 ECTs with a passed induction')
        expect(batch_action_summary(batch)).to have_text('0 ECTs with a failed induction')
        expect(batch_action_summary(batch)).to have_text('0 ECTs with a released outcome')
      end
    end

    describe '#admin_batch_list_table' do
      subject(:table) { admin_batch_list_table(batches) }

      let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: 'The Appropriate Body') }

      let(:batches) do
        [
          FactoryBot.create(:pending_induction_submission_batch, :action, :completed, appropriate_body:),
          FactoryBot.create(:pending_induction_submission_batch, :claim, :processing, appropriate_body:)
        ]
      end

      it do
        expect(table).to have_selector('table tr', count: 3)
        expect(table).to have_selector('th', text: 'Batch ID')
        expect(table).to have_selector('th', text: 'Appropriate Body')
        expect(table).to have_selector('th', text: 'Type')
        expect(table).to have_selector('th', text: 'Status')
        expect(table).to have_selector('th', text: 'Filename')
        expect(table).to have_selector('th', text: 'Created')
        expect(table).to have_selector('th', text: 'CSV Rows')
        expect(table).to have_selector('th', text: 'Processed')
        expect(table).to have_selector('th', text: 'Errors')
        expect(table).to have_selector('th', text: 'Action')

        expect(table).to have_selector('td', text: 'The Appropriate Body')
        expect(table).to have_selector('td', text: 'Action')
        expect(table).to have_selector('td', text: 'Completed')
        expect(table).to have_selector('td', text: 'Claim')
        expect(table).to have_selector('td', text: 'Processing')
      end
    end
  end
end
