RSpec.describe Teachers::Details::CurrentInductionPeriodComponent, type: :component do
  include AppropriateBodyHelper
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(mode:, teacher:) }

  let(:mode) { :appropriate_body }
  let(:teacher) { FactoryBot.create(:teacher) }

  context "when teacher has no current induction period" do
    it "will not render" do
      expect(component.render?).to be false
    end
  end

  context "when teacher has a current induction period" do
    let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: "Test AB") }
    let!(:current_period) do
      FactoryBot.create(:induction_period, :active,
                        teacher:,
                        appropriate_body:,
                        started_on: '2025-06-30',
                        induction_programme: 'fip')
    end

    before { render_inline(component) }

    it "will render" do
      expect(component.render?).to be true
    end

    it "displays the heading" do
      expect(page).to have_css("h2", text: "Current induction period")
    end

    it "displays the appropriate body name" do
      expect(page).to have_css("h3", text: "Test AB")
    end

    it "formats the start date" do
      expect(page).to have_text('30 June 2025')
    end

    describe '#enable_release' do
      subject(:component) { described_class.new(mode:, teacher:, enable_release:) }

      before { render_inline(component) }

      context "when true" do
        let(:enable_release) { true }

        context "and in admin mode" do
          let(:mode) { :admin }

          it "does not render a release link" do
            expect(page).not_to have_link("Release")
          end
        end

        context "and in appropriate body mode" do
          it "renders an AB release link" do
            expect(page).to have_link("Release", href: new_ab_teacher_release_ect_path(teacher))
          end
        end
      end

      context "when nil" do
        let(:enable_release) { nil }

        it "does not render a release link" do
          expect(page).not_to have_link("Release")
        end
      end

      context "when false" do
        let(:enable_release) { false }

        it "does not render a release link" do
          expect(page).not_to have_link("Release")
        end
      end
    end

    describe '#enable_edit' do
      subject(:component) { described_class.new(mode:, teacher:, enable_edit:) }

      before { render_inline(component) }

      context "when true" do
        let(:enable_edit) { true }

        context "and in admin mode" do
          let(:mode) { :admin }

          it "renders admin edit and delete links" do
            expect(page).to have_link("Edit", href: edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id))
            expect(page).to have_link("Delete", href: confirm_delete_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id))
          end
        end

        context "and in appropriate body mode" do
          let(:mode) { :appropriate_body }

          it "renders appropriate body edit and delete links" do
            expect(page).to have_link("Edit", href: edit_ab_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id))
            expect(page).to have_link("Delete", href: confirm_delete_ab_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id))
          end
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

          it "renders an edit link" do
            expect(page).to have_link("Edit")
          end

          it "does not render a delete link even when enable_edit true" do
            expect(page).not_to have_link("Delete")
          end
        end
      end

      context "when nil" do
        let(:enable_edit) { nil }

        it "does not render a edit or delete links" do
          expect(page).not_to have_link("Edit")
          expect(page).not_to have_link("Delete")
        end
      end

      context "when false" do
        let(:enable_edit) { false }

        it "does not render a edit or delete links" do
          expect(page).not_to have_link("Edit")
          expect(page).not_to have_link("Delete")
        end
      end
    end
  end
end
