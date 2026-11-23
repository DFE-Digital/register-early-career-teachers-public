RSpec.describe Teachers::Details::PersonalDetailsComponent, type: :component do
  subject(:component) { described_class.new(teacher:) }

  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Richard", trs_last_name: "Prior") }

  before { render_inline(component) }

  it "renders the personal details" do
    expect(page).to have_text("Personal details")
    expect(page).to have_text("Richard Prior")
  end
end
