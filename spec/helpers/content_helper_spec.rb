RSpec.describe ContentHelper, type: :helper do
  describe "#generic_email_label" do
    let(:label) { helper.generic_email_label }

    it 'returns the label' do
      expect(label).to include('Do not use a generic email like')
      expect(label).to end_with(".")
    end

    it 'renders the link' do
      expect(label).to include('admin@example.com')
      expect(label).to include("govuk-link--no-visited-state")
    end
  end
end
