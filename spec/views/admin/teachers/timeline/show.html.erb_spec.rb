RSpec.describe "admin/teachers/timeline/show.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:events) { [] }

  before do
    assign(:teacher, Admin::TeacherPresenter.new(teacher))
    assign(:events, events)
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

  context "with timeline events" do
    let(:events) { [FactoryBot.build(:event, :with_body)] }

    it "renders event titles as level 3 headings" do
      expect(rendered).to have_css("h3.app-timeline__title", text: events.first.heading)
    end
  end
end
