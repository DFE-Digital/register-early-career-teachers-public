RSpec.describe 'admin/teachers/show.html.erb' do
  let(:teacher) { create(:teacher, trn: '1234567', trs_first_name: 'Floella', trs_last_name: 'Benjamin') }

  before do
    create(:induction_period, :active, teacher:)
    assign(:teacher, Admin::TeacherPresenter.new(teacher))
    render
  end

  it 'includes a back link to admin teachers list' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: admin_teachers_path)
  end

  it 'displays teacher information' do
    expect(view.content_for(:page_title)).to eql('Floella Benjamin')
    expect(view.content_for(:page_header)).to have_css('h1', text: 'Floella Benjamin')
    expect(view.content_for(:page_caption)).to have_text('TRN: 1234567')
  end

  it 'displays induction information' do
    expect(rendered).to have_text('Current induction period')
  end

  it 'links to teacher timeline' do
    expect(rendered).to have_link('View change history', href: admin_teacher_timeline_path(teacher))
  end

  context 'when there are no migration failures' do
    it 'does not report migration failures' do
      expect(rendered).not_to have_text("Some of this teacher's records could not be migrated")
    end
  end
end
