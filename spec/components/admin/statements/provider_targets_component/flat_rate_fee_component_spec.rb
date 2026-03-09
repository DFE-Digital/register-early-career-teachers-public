RSpec.describe Admin::Statements::ProviderTargetsComponent::FlatRateFeeComponent, type: :component do
  subject(:component) { described_class.new(contract:) }

  let(:contract) { FactoryBot.build_stubbed(:contract, flat_rate_fee_structure:) }
  let(:flat_rate_fee_structure) do
    FactoryBot.create(
      :contract_flat_rate_fee_structure,
      recruitment_target: 3000,
      fee_per_declaration: 750
    )
  end

  before { render_inline(component) }

  context "when there is no flat rate fee structure" do
    let(:flat_rate_fee_structure) { nil }

    it "does not render anything" do
      expect(page).to have_no_selector("body")
    end
  end

  it "renders the recruitment target" do
    expect(page).to have_summary_list_row("Mentors recruitment target", value: "3000")
  end

  it "renders the payment per participant" do
    expect(page).to have_summary_list_row("Payment per participant", value: "£750.00")
  end
end
