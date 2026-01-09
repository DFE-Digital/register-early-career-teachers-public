RSpec.describe Teachers::OutcomeFormFieldsComponent, type: :component do
  subject(:component) do
    described_class.new(mode:, form:, appropriate_body:)
  end

  let(:model) { double("model", number_of_terms: nil, finished_on: nil) }

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:model_name, model, ActionView::Base.empty, {})
  end

  before { render_inline(component) }

  context "without appropriate body" do
    let(:mode) { :admin }
    let(:appropriate_body) { nil }

    it "finished_on" do
      expect(rendered_content).to have_field("model_name[finished_on(1i)]")
      expect(rendered_content).to have_field("model_name[finished_on(2i)]")
      expect(rendered_content).to have_field("model_name[finished_on(3i)]")
      expect(rendered_content).to have_text("When did they complete their induction?")
    end

    it "number_of_terms" do
      expect(rendered_content).to have_field("model_name[number_of_terms]")
      expect(rendered_content).to have_text("How many terms of induction did they complete?")
    end
  end

  context "with appropriate body" do
    let(:mode) { :appropriate_body }
    let(:appropriate_body) { FactoryBot.build(:appropriate_body, name: "OmniCorp") }

    it "finished_on" do
      expect(rendered_content).to have_field("model_name[finished_on(1i)]")
      expect(rendered_content).to have_field("model_name[finished_on(2i)]")
      expect(rendered_content).to have_field("model_name[finished_on(3i)]")
      expect(rendered_content).to have_text("When did their induction end with OmniCorp?")
    end

    it "number_of_terms" do
      expect(rendered_content).to have_field("model_name[number_of_terms]")
      expect(rendered_content).to have_text("How many terms of induction did they spend with you?")
    end
  end
end
