RSpec.describe "appropriate_bodies/teachers/extensions/new.html.erb" do
  let(:appropriate_body) { build(:appropriate_body) }
  let(:teacher) { create(:teacher) }
  let(:extension) { build(:induction_extension) }

  before do
    assign(:appropriate_body, appropriate_body)
    assign(:teacher, teacher)
    assign(:extension, extension)
  end

  it "renders a form with a 'FTE terms' field" do
    render

    expect(rendered).to have_css('label', text: 'FTE terms')
  end

  context 'when the extension has an error' do
    let(:extension) { build(:induction_extension, number_of_terms: 17) }

    before do
      extension.valid?
    end

    it 'shows the error message on the page' do
      render

      expect(rendered).to have_css('.govuk-form-group--error', text: /Number of terms must be between 0.1 and 16/)
    end
  end
end
