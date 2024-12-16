require "rails_helper"

RSpec.describe Teachers::CurrentInductionPeriodComponent, type: :component do
  include AppropriateBodyHelper
  include Rails.application.routes.url_helpers

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher: teacher) }

  context "when teacher has no current induction period" do
    it "does not render" do
      expect(component.render?).to be false
    end
  end

  context "when teacher has a current induction period" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Test AB") }
    let!(:current_period) do
      FactoryBot.create(:induction_period,
                        teacher: teacher,
                        appropriate_body: appropriate_body,
                        started_on: 6.months.ago,
                        finished_on: nil,
                        induction_programme: "cip")
    end

    it "renders" do
      expect(component.render?).to be true
    end

    it "displays the appropriate body name" do
      render_inline(component)
      expect(page).to have_content("Test AB")
    end

    it "displays the start date" do
      render_inline(component)
      expect(page).to have_content(6.months.ago.to_date.to_fs(:govuk))
    end

    it "includes a release link" do
      render_inline(component)
      expect(page).to have_link("Release", href: new_ab_teacher_release_ect_path(teacher_trn: teacher.trn))
    end

    it "includes a change programme link" do
      render_inline(component)
      expect(page).to have_link("Change", href: "#")
    end
  end
end
