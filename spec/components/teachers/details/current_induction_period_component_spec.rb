RSpec.describe Teachers::Details::CurrentInductionPeriodComponent, type: :component do
  include AppropriateBodyHelper
  include Rails.application.routes.url_helpers

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher:) }

  context "when teacher has no current induction period" do
    it "does not render" do
      expect(component.render?).to be false
    end
  end

  context "when teacher has a current induction period" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Test AB") }
    let!(:current_period) do
      FactoryBot.create(:induction_period, :active,
                        teacher:,
                        appropriate_body:,
                        started_on: 6.months.ago,
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

    it "includes a release link when enable_release is true" do
      component = described_class.new(teacher:, enable_release: true)
      render_inline(component)
      expect(page).to have_link("Release", href: new_ab_teacher_release_ect_path(teacher))
    end

    it "does not include a release link when enable_release nil" do
      component = described_class.new(teacher:)
      render_inline(component)
      expect(page).not_to have_link("Release")
    end

    it "includes an edit link when enable_edit is true" do
      component = described_class.new(teacher:, enable_edit: true)
      render_inline(component)
      expect(page).to have_link("Edit", href: edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id))
    end

    it "does not include an edit link when edit_release nil" do
      component = described_class.new(teacher:)
      render_inline(component)
      expect(page).not_to have_link("Edit")
    end

    it "includes a delete link when enable_edit is true" do
      component = described_class.new(teacher:, enable_edit: true)
      render_inline(component)
      expect(page).to have_link("Delete", href: confirm_delete_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id))
    end

    it "does not include a delete link when enable_edit is false" do
      component = described_class.new(teacher:)
      render_inline(component)
      expect(page).not_to have_link("Delete")
    end

    context "when the induction period has an outcome" do
      let!(:current_period) do
        FactoryBot.create(:induction_period, :active,
                          teacher:,
                          appropriate_body:,
                          started_on: 6.months.ago,
                          outcome: "pass",
                          induction_programme: "cip")
      end

      it "includes an edit link when enable_edit is true" do
        component = described_class.new(teacher:, enable_edit: true)
        render_inline(component)
        expect(page).to have_link("Edit", href: edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id))
      end

      it "does not include a delete link even when enable_edit true" do
        component = described_class.new(teacher:, enable_edit: true)
        render_inline(component)
        expect(page).not_to have_link("Delete")
      end
    end
  end
end
