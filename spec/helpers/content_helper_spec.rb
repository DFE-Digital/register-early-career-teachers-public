RSpec.describe ContentHelper, type: :helper do
  describe "#generic_email_label" do
    let(:label) { helper.generic_email_label }

    it 'returns the label' do
      expect(label).to eql('Do not use a generic email like headteacher@school.com')
    end
  end
end
