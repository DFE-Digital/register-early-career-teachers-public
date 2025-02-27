require "rails_helper"

RSpec.describe Teachers::PersonalDetailsComponent, type: :component do
  include TeacherHelper

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher:) }

  it "renders the personal details" do
    render_inline(component)

    expect(page).to have_content("Personal details")
    expect(page).to have_content(teacher_full_name(teacher))
  end
end
