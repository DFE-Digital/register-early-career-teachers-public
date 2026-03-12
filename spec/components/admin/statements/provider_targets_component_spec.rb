RSpec.describe Admin::Statements::ProviderTargetsComponent, type: :component do
  subject(:component) { described_class.new(statement:) }

  let(:statement) { FactoryBot.create(:statement) }

  before do
    allow(Admin::Statements::ProviderTargetsComponent::BandedFeeComponent)
      .to receive(:new)
      .with(contract: statement.contract)
      .and_call_original
    allow(Admin::Statements::ProviderTargetsComponent::FlatRateFeeComponent)
      .to receive(:new)
      .with(contract: statement.contract)
      .and_call_original

    render_inline(component)
  end

  it "renders the provider targets" do
    expect(page).to have_css("details", text: "Provider targets (per academic year)")
  end

  it "renders the lead provider name" do
    expect(page).to have_summary_list_row(
      "Provider",
      value: statement.lead_provider.name,
      visible: :hidden
    )
  end

  it "renders the banded fee contract targets" do
    expect(Admin::Statements::ProviderTargetsComponent::BandedFeeComponent)
      .to have_received(:new)
      .with(contract: statement.contract)
  end

  it "renders the flat rate fee contract targets" do
    expect(Admin::Statements::ProviderTargetsComponent::FlatRateFeeComponent)
      .to have_received(:new)
      .with(contract: statement.contract)
  end
end
