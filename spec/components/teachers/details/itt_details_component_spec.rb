require "rails_helper"

RSpec.describe Teachers::Details::ITTDetailsComponent, type: :component do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher:) }

  context "when teacher has QTS award date and ITT provider" do
    let(:teacher) do
      FactoryBot.create(
        :teacher,
        trs_qts_awarded_on: 1.year.ago,
        trs_initial_teacher_training_provider_name: "Test University"
      )
    end

    it "renders QTS awarded date and ITT provider" do
      render_inline(component)

      expect(page).to have_content("Initial teacher training details")
      expect(page).to have_content("QTS awarded")
      expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
      expect(page).to have_content("Initial teacher training provider")
      expect(page).to have_content("Test University")
    end
  end

  context "when teacher has no QTS award date" do
    let(:teacher) do
      FactoryBot.create(
        :teacher,
        trs_qts_awarded_on: nil,
        trs_initial_teacher_training_provider_name: "Test University"
      )
    end

    it "does not render QTS awarded section" do
      render_inline(component)

      expect(page).to have_content("Initial teacher training details")
      expect(page).not_to have_content("QTS awarded")
      expect(page).to have_content("Initial teacher training provider")
      expect(page).to have_content("Test University")
    end
  end

  context "when teacher has no ITT provider" do
    let(:teacher) do
      FactoryBot.create(
        :teacher,
        trs_qts_awarded_on: 1.year.ago,
        trs_initial_teacher_training_provider_name: nil
      )
    end

    it "does not render ITT provider section" do
      render_inline(component)

      expect(page).to have_content("Initial teacher training details")
      expect(page).to have_content("QTS awarded")
      expect(page).to have_content(1.year.ago.to_date.to_fs(:govuk))
      expect(page).not_to have_content("Initial teacher training provider")
    end
  end

  context "when teacher has neither QTS award date nor ITT provider" do
    let(:teacher) do
      FactoryBot.create(
        :teacher,
        trs_qts_awarded_on: nil,
        trs_initial_teacher_training_provider_name: nil
      )
    end

    it "renders the component with just the heading" do
      render_inline(component)

      expect(page).to have_content("Initial teacher training details")
      expect(page).not_to have_content("QTS awarded")
      expect(page).not_to have_content("Initial teacher training provider")
    end
  end
end
