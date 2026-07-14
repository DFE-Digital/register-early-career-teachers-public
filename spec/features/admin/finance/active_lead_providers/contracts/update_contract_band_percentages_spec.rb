RSpec.describe "Update contract band percentages", :js do
  before { sign_in_as_dfe_user(role: :finance) }

  scenario "Output fee percentage drives service fee percentage" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page
    then_i_see_the_banded_fee_structure_table

    when_i_change_the_output_fee_percentage_to("30")
    then_the_service_fee_percentage_is("70")

    when_i_change_the_output_fee_percentage_to("60")
    then_the_service_fee_percentage_is("40")
  end

  scenario "Output fee percentage is clamped to 0..100" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    when_i_change_the_output_fee_percentage_to("150")
    then_the_output_fee_percentage_is("100")
    and_the_service_fee_percentage_is("0")

    when_i_change_the_output_fee_percentage_to("-20")
    then_the_output_fee_percentage_is("0")
    and_the_service_fee_percentage_is("100")
  end

  scenario "Output fee percentage is rounded to whole numbers" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    when_i_change_the_output_fee_percentage_to("33.7")
    then_the_output_fee_percentage_is("34")
    and_the_service_fee_percentage_is("66")

    when_i_change_the_output_fee_percentage_to("49.4")
    then_the_output_fee_percentage_is("49")
    and_the_service_fee_percentage_is("51")
  end

  scenario "Service fee percentage input is read-only" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    then_the_service_fee_input_is_read_only
    and_the_service_fee_input_is_not_tabable
  end

  def given_an_editable_contract_with_bands_exists
    @contract_period = FactoryBot.create(:contract_period, :next)

    @active_lead_provider = FactoryBot.create(:active_lead_provider,
                                              contract_period: @contract_period)

    @contract = FactoryBot.create(:contract, :for_ittecf_ectp, :with_bands_and_band_terms,
                                  active_lead_provider: @active_lead_provider)
  end

  def when_i_visit_the_contract_edit_page
    page.goto(edit_admin_finance_active_lead_provider_contract_path)
  end

  def then_i_see_the_banded_fee_structure_table
    expect(page.get_by_role("heading", name: "Banded fee structure")).to be_visible
    expect(page.get_by_role("table")).to be_visible
  end

  def when_i_change_the_output_fee_percentage_to(value)
    output_input.fill(value.to_s)
  end

  def then_the_output_fee_percentage_is(value)
    expect(output_input.input_value).to eq(value.to_s)
  end

  def then_the_service_fee_percentage_is(value)
    expect(service_input.input_value).to eq(value.to_s)
  end
  alias_method :and_the_service_fee_percentage_is, :then_the_service_fee_percentage_is

  def then_the_service_fee_input_is_read_only
    expect(service_input).to have_attribute("readonly", "readonly")
  end

  def and_the_service_fee_input_is_not_tabable
    expect(service_input).to have_attribute("tabindex", "-1")
  end

  def output_input
    page.get_by_label("Band A output fee percentage", exact: true)
  end

  def service_input
    page.get_by_label("Band A service fee percentage", exact: true)
  end

  def edit_admin_finance_active_lead_provider_contract_path
    "/admin/finance/contract-periods/#{@contract_period.year}/active-lead-providers/#{@active_lead_provider.id}/contracts/#{@contract.id}/edit"
  end
end
