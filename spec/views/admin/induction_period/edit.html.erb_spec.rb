RSpec.describe 'admin/induction_periods/edit.html.erb' do
  let(:ect) { create(:ect_at_school_period, :active) }
  let(:back_path) { admin_teacher_path(ect.teacher) }
  let(:induction_period) { create(:induction_period, teacher: ect.teacher) }

  before do
    assign(:induction_period, induction_period)
  end

  it 'includes a back button that links to the ECT admin page' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end
end
