require "rails_helper"

RSpec.describe Teachers::Details::InductionSummaryComponent, type: :component do
  include AppropriateBodyHelper
  include Rails.application.routes.url_helpers

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher:) }

  context "when teacher has no induction periods" do
    it "does not render" do
      expect(component.render?).to be false
    end
  end

  context "#render_extension_links?" do
    context "when the user is an admin" do
      let(:component) { described_class.new(teacher:, is_admin: true) }

      it "returns false" do
        expect(component.render_extension_links?).to be false
      end
    end

    context "when the user is not an admin" do
      it "returns true" do
        expect(component.render_extension_links?).to be true
      end
    end
  end

  context "when teacher has induction periods" do
    let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, started_on: 1.year.ago) }

    it "renders" do
      expect(component.render?).to be true
    end

    it "displays the induction start date" do
      render_inline(component)
      expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
    end

    context "QTS awarded" do
      context "when the teacher has a QTS award date" do
        let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }

        it "renders QTS awarded" do
          render_inline(component)
          expect(page).to have_content("QTS awarded")
          expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
        end
      end

      context "when the teacher does not have a QTS award date" do
        it "does not render QTS awarded on" do
          render_inline(component)
          expect(page).not_to have_content("QTS awarded")
        end
      end
    end

    context "Initial Teacher Training" do
      context "when teacher has ITT provider name" do
        let(:teacher) { FactoryBot.create(:teacher, trs_initial_teacher_training_provider_name: "Test University") }

        it "renders ITT section with provider name" do
          render_inline(component)
          expect(page).to have_content("Initial teacher training records")
          expect(page).to have_content("Test University")
          # FIXME: we have removed this link for MVP
          # expect(page).to have_link("View", href: ab_teacher_initial_teacher_training_records_path(teacher))
        end
      end

      context "when teacher has no ITT provider name" do
        let(:teacher) { FactoryBot.create(:teacher, trs_initial_teacher_training_provider_name: nil) }

        it "does not render ITT section" do
          render_inline(component)

          expect(page).not_to have_content("Initial teacher training records")
        end
      end
    end

    context "with extensions" do
      let!(:extension) { FactoryBot.create(:induction_extension, teacher:) }

      it "displays extension information" do
        render_inline(component)
        expect(page).to have_content("Extensions")
        expect(page).to have_link("View", href: ab_teacher_extensions_path(teacher))
      end
    end

    context "without extensions" do
      it "displays no extension information" do
        render_inline(component)
        expect(page).to have_content("Extensions")
        expect(page).to have_content("None")
        expect(page).to have_link("Add", href: ab_teacher_extensions_path(teacher))
      end
    end
  end
end
