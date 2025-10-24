RSpec.describe Teachers::OutcomeFormComponent, type: :component do
  subject(:component) do
    described_class.new(form:, appropriate_body:)
  end

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(
      :pending_induction_submission,
      PendingInductionSubmission.new,
      ActionView::Base.empty,
      {}
    )
  end

  before { render_inline(component) }

  context "without appropriate body" do
    let(:appropriate_body) { nil }

    it "finished_on" do
      expect(rendered_content).to have_text("When did they complete their induction?")
    end

    it "number_of_terms" do
      expect(rendered_content).to have_text("How many terms of induction did they complete?")
    end
  end

  context "with appropriate body" do
    let(:appropriate_body) { FactoryBot.build(:appropriate_body, name: 'OmniCorp') }

    it "finished_on" do
      expect(rendered_content).to have_text("When did they move from OmniCorp?")
    end

    it "number_of_terms" do
      expect(rendered_content).to have_text("How many terms of induction did they spend with you?")
    end
  end
end
