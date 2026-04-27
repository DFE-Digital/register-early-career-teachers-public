RSpec.describe "admin/teachers/timeline/show.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    assign(:teacher, Admin::TeacherPresenter.new(teacher))
    assign(:events, [])
    assign(:breadcrumbs, {
      "Teachers" => admin_teachers_path,
      "Floella Benjamin" => admin_teacher_path(teacher),
      "Timeline" => nil
    })
    render
  end

  it "includes a breadcrumb to admin teachers list" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Teachers", href: admin_teachers_path)
  end
end
