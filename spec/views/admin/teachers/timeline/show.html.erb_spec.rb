RSpec.describe "admin/teachers/timeline/show.html.erb" do
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    assign(:teacher, teacher)
    assign(:events, [])
    render
  end

  it "includes a back link to the teacher page" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_teacher_path(teacher))
  end
end
