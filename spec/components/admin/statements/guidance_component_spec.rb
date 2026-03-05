RSpec.describe Admin::Statements::GuidanceComponent, type: :component do
  subject(:component) { render_inline(described_class.new) }

  it { is_expected.to have_css("details", text: "Calculation rounding errors") }
  it { is_expected.to have_css("details", text: "Updated financial statement design") }
end
