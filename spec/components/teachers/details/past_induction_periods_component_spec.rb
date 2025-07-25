RSpec.describe Teachers::Details::PastInductionPeriodsComponent, type: :component do
  subject(:component) { described_class.new(teacher:, enable_edit:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:enable_edit) { false }

  context "when teacher has no past induction periods" do
    it "does not render" do
      expect(component.render?).to be false
      render_inline(component)
      expect(rendered_content).to be_empty
    end
  end

  context "when teacher has past induction periods" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Past AB") }
    let!(:past_induction_period) do
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body:,
                        started_on: Date.new(2021, 9, 1),
                        finished_on: 1.year.ago,
                        induction_programme: "cip",
                        number_of_terms: 3)
    end

    before { render_inline(component) }

    it "renders" do
      expect(component.render?).to be true
      render_inline(component)
      expect(rendered_content).not_to be_empty
    end

    it "displays the heading" do
      expect(page).to have_css("h2", text: "Past induction periods")
    end

    it "displays the appropriate body name" do
      expect(page).to have_css("h3", text: "Past AB")
    end

    it "displays the start date" do
      expect(page).to have_content(Date.new(2021, 9, 1).to_fs(:govuk))
    end

    it "displays the end date" do
      expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
    end

    it "displays the number of terms" do
      expect(page).to have_content("3")
    end

    context "when edit is enabled" do
      let(:enable_edit) { true }

      it "renders actions when edit is enabled" do
        expect(page).to have_link(
          "Edit",
          href: "/admin/teachers/#{teacher.id}/induction-periods/#{past_induction_period.id}/edit"
        )
        expect(page).to have_link(
          "Delete",
          href: "/admin/teachers/#{teacher.id}/induction-periods/#{past_induction_period.id}/confirm-delete"
        )
      end
    end

    context "when edit is disabled" do
      let(:enable_edit) { false }

      it "does not render actions when edit is disabled" do
        expect(page).not_to have_link("Edit")
        expect(page).not_to have_link("Delete")
      end
    end
  end
end
