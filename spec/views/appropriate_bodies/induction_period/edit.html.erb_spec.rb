RSpec.describe 'appropriate_bodies/induction_periods/edit.html.erb' do
  let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
  let(:back_path) { ab_teacher_path(ect.teacher) }
  let(:induction_period) { FactoryBot.create(:induction_period, teacher: ect.teacher) }

  before do
    assign(:induction_period, induction_period)
  end

  it 'includes a back button that links to the ECT admin page' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'renders old or new induction types via feature flag' do
    allow(Rails.application.config).to receive(:enable_bulk_claim).and_return(false)
    render

    expect(rendered).to have_text('Full induction programme')
    expect(rendered).to have_text('Core induction programme')
    expect(rendered).to have_text('School-based induction programme')

    allow(Rails.application.config).to receive(:enable_bulk_claim).and_return(true)
    render

    expect(rendered).to have_text('Provider-led')
    expect(rendered).to have_text('School-led')
  end
end
