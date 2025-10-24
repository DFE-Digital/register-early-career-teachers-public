RSpec.describe Admin::ContextFormFieldsComponent, type: :component do
  subject(:component) { described_class.new(form:) }

  let(:model) { double("model", note: nil, zendesk_ticket_id: nil) }

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(:model_name, model, ActionView::Base.empty, {})
  end

  before { render_inline(component) }

  it "renders fields", :aggregate_failures do
    expect(rendered_content).to have_text("Explain why you're making this change")

    expect(rendered_content).to have_field('model_name[note]')
    expect(rendered_content).to have_text("Add a note to explain why you're making this change")

    expect(rendered_content).to have_field('model_name[zendesk_ticket_id]')
    expect(rendered_content).to have_text("Enter Zendesk ticket number")
  end
end
