RSpec.describe Teachers::Details::PastInductionPeriodsComponent, type: :component do
  include AppropriateBodyHelper

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher:) }

  context "when teacher has no past induction periods" do
    it "does not render" do
      expect(component.render?).to be false
    end
  end

  context "when teacher has past induction periods" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Past AB") }
    let!(:past_period) do
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: Date.new(2021, 9, 1),
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
      expect(page).to have_content(Date.new(2021, 9, 1).to_fs(:govuk))
    end

    it "displays the end date" do
      render_inline(component)
      expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
    end

    it "displays the number of terms" do
      render_inline(component)
      expect(page).to have_content("3")
    end
  end
end
