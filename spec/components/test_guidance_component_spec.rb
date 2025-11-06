describe TestGuidanceComponent, type: :component do
  context 'when disabled' do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(false)
      render_inline(described_class.new) { "some content" }
    end

    it 'does not render content' do
      expect(rendered_content).to be_blank
    end
  end

  context 'when enabled' do
    before do
      allow(Rails.application.config).to receive(:enable_test_guidance).and_return(true)
      render_inline(described_class.new) { "some content" }
    end

    it 'renders content' do
      expect(rendered_content).to have_text("some content")
    end

    describe 'TRS example details' do
      before do
        render_inline(described_class.new, &:with_trs_example_teacher_details)
      end

      it 'contains a table with TRNs and dates of birth' do
        expect(rendered_content).to have_text('To successfully locate an ECT from the TRS API')
        expect(rendered_content).to have_table

        ["Name", "TRN", "Date of birth", "Induction status", "Claimed by", ""].each do |header|
          expect(rendered_content).to have_selector('table thead tr th', text: header)
        end

        ["Chloe Nolan", "3002586", "1977-02-03"].each do |cell|
          expect(rendered_content).to have_selector('table tbody tr td', text: cell)
        end
      end
    end

    describe 'fake TRS API example details' do
      before do
        render_inline(described_class.new, &:with_trs_fake_api_instructions)
      end

      it 'contains a list of fake TRNs' do
        expect(rendered_content).to have_text('Enter any TRN with the date of birth 03-02-1977 to register a random ECT.')
      end
    end
  end
end
