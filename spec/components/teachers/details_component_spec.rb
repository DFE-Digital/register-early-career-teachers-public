require "rails_helper"

RSpec.describe Teachers::DetailsComponent, type: :component do
  include ActionView::Helpers::TagHelper
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:component) { described_class.new(teacher:) }

  it "renders slots when provided" do
    result = render_inline(component) do |c|
      c.with_personal_details { tag.div("Personal Details Content") }
      c.with_itt_details { tag.div("ITT Details Content") }
      c.with_induction_summary { tag.div("Induction Summary Content") }
      c.with_current_induction_period { tag.div("Current Induction Period Content") }
      c.with_past_induction_periods { tag.div("Past Induction Periods Content") }
    end

    html = result.to_html
    expect(html).to include("Personal Details Content")
    expect(html).to include("ITT Details Content")
    expect(html).to include("Induction Summary Content")
    expect(html).to include("Current Induction Period Content")
    expect(html).to include("Past Induction Periods Content")
  end

  it "doesn't render slots that aren't provided" do
    result = render_inline(component) do |c|
      c.with_personal_details { tag.div("Personal Details Content") }
    end

    html = result.to_html
    expect(html).to include("Personal Details Content")
    expect(html).not_to include("ITT Details Content")
    expect(html).not_to include("Induction Summary Content")
    expect(html).not_to include("Current Induction Period Content")
    expect(html).not_to include("Past Induction Periods Content")
  end
end
