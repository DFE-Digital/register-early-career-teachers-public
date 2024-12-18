require "rails_helper"

RSpec.describe Teachers::PastInductionPeriodsComponent, type: :component do
  include AppropriateBodyHelper

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher: teacher) }

  context "when teacher has no past induction periods" do
    it "does not render" do
      expect(component.render?).to be false
    end
  end

  context "when teacher has past induction periods" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Past AB") }
    let!(:past_period) do
      FactoryBot.create(:induction_period,
                        teacher: teacher,
                        appropriate_body: appropriate_body,
                        started_on: 2.years.ago,
                        finished_on: 1.year.ago,
                        induction_programme: "cip",
                        number_of_terms: 3)
    end

    it "renders" do
      expect(component.render?).to be true
    end

    it "displays the appropriate body name" do
      render_inline(component)
      expect(page).to have_content("Past AB")
    end

    it "displays the start date" do
      render_inline(component)
      expect(page).to have_content(2.years.ago.to_date.to_fs(:govuk))
    end

    it "displays the end date" do
      render_inline(component)
      expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
    end

    it "displays the number of terms" do
      render_inline(component)
      expect(page).to have_content("3")
    end

    context "with multiple past periods" do
      let!(:older_period) do
        FactoryBot.create(:induction_period,
                          teacher: teacher,
                          started_on: 4.years.ago,
                          finished_on: 3.years.ago)
      end

      it "displays all past periods in chronological order" do
        render_inline(component)
        dates = page.all(".govuk-summary-list__value").map(&:text)
        expect(dates).to include(4.years.ago.to_date.to_fs(:govuk))
        expect(dates).to include(3.years.ago.to_date.to_fs(:govuk))
      end
    end
  end
end
