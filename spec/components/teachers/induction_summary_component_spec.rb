require "rails_helper"

RSpec.describe Teachers::InductionSummaryComponent, type: :component do
  include AppropriateBodyHelper
  include Rails.application.routes.url_helpers

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher: teacher) }

  context "when teacher has no induction periods" do
    it "does not render" do
      expect(component.render?).to be false
    end
  end

  context "when teacher has induction periods" do
    let!(:induction_period) { FactoryBot.create(:induction_period, teacher: teacher, started_on: 1.year.ago) }

    it "renders" do
      expect(component.render?).to be true
    end

    it "displays the induction start date" do
      render_inline(component)
      expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
    end

    context "with extensions" do
      let!(:extension) { FactoryBot.create(:induction_extension, teacher: teacher) }

      it "displays extension information" do
        render_inline(component)
        expect(page).to have_content("Extended by")
        expect(page).to have_link("View", href: ab_teacher_extensions_path(teacher_trn: teacher.trn))
      end
    end

    context "without extensions" do
      it "displays no extension information" do
        render_inline(component)
        expect(page).to have_content("Extended")
        expect(page).to have_content("No")
        expect(page).to have_link("Add", href: new_ab_teacher_extension_path(teacher_trn: teacher.trn))
      end
    end
  end
end
