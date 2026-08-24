RSpec.describe "Update contract band percentages", :js do
  before { sign_in_as_dfe_user(role: :finance) }

  scenario "Output fee percentage drives service fee percentage" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page
    then_i_see_the_banded_fee_structure_table

    when_i_change_the_output_fee_percentage_to("30")
    then_the_service_fee_percentage_is("70")
    and_the_service_fee_is_announced_as("Service fee 70%")

    when_i_change_the_output_fee_percentage_to("60")
    then_the_service_fee_percentage_is("40")
    and_the_service_fee_is_announced_as("Service fee 40%")
  end

  scenario "Output fee percentage is capped to 0..100 when the field is left" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    when_i_change_the_output_fee_percentage_to("150")
    then_the_service_fee_percentage_is("")

    and_i_move_away_from_the_output_fee_field
    then_the_output_fee_percentage_is("100")
    and_the_service_fee_percentage_is("0")

    when_i_change_the_output_fee_percentage_to("-20")
    then_the_service_fee_percentage_is("")

    and_i_move_away_from_the_output_fee_field
    then_the_output_fee_percentage_is("0")
    and_the_service_fee_percentage_is("100")
  end

  scenario "Output fee percentage is rounded to whole numbers when the field is left" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    when_i_change_the_output_fee_percentage_to("33.7")
    then_the_output_fee_percentage_is("33.7")

    and_i_move_away_from_the_output_fee_field
    then_the_output_fee_percentage_is("34")
    and_the_service_fee_percentage_is("66")

    when_i_change_the_output_fee_percentage_to("49.4")
    and_i_move_away_from_the_output_fee_field
    then_the_output_fee_percentage_is("49")
    and_the_service_fee_percentage_is("51")
  end

  scenario "Service fee percentage input is read-only" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    then_the_service_fee_input_is_read_only
    and_the_service_fee_input_is_not_tabable
    and_the_service_fee_input_is_not_submitted
  end

  scenario "Service fee percentage changes are announced to screen readers" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    then_the_service_fee_status_is_a_polite_live_region
    and_it_is_silent_until_something_changes
    and_the_output_fee_input_is_described_by_the_hint_and_the_status
  end

  scenario "Only the final service fee percentage is announced while typing" do
    given_an_editable_contract_with_bands_exists
    when_i_visit_the_contract_edit_page

    when_i_type_the_output_fee_percentage("60")
    then_nothing_is_announced_yet
    and_the_service_fee_is_announced_as("Service fee 40%")
  end

  context "without JavaScript", js: false do
    scenario "Service fee percentage is worked out by the server" do
      given_an_editable_contract_with_bands_exists
      when_i_visit_the_contract_edit_page
      then_the_service_fee_percentage_is("")

      when_i_change_the_output_fee_percentage_to("30")
      and_the_service_fee_percentage_is("")

      when_i_save_the_contract
      then_the_band_term_percentages_are(output: 0.3, service: 0.7)
    end
  end

  def given_an_editable_contract_with_bands_exists
    @contract_period = FactoryBot.create(:contract_period, :next)

    @framework_agreement = FactoryBot.create(:framework_agreement,
                                             contract_period: @contract_period)

    @contract = FactoryBot.create(:contract, :for_ittecf_ectp, :with_bands_and_band_terms,
                                  framework_agreement: @framework_agreement)
  end

  def when_i_visit_the_contract_edit_page
    page.goto(edit_admin_finance_framework_agreement_contract_path)
  end

  def then_i_see_the_banded_fee_structure_table
    expect(page.get_by_role("heading", name: "Banded fee structure")).to be_visible
    expect(page.get_by_role("table")).to be_visible
  end

  def when_i_change_the_output_fee_percentage_to(value)
    output_input.fill(value.to_s)
  end

  def and_i_move_away_from_the_output_fee_field
    output_input.blur
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

  def and_the_service_fee_input_is_not_submitted
    expect(service_input.get_attribute("name")).to be_nil
  end

  def and_the_service_fee_is_announced_as(announcement)
    expect(service_fee_status).to have_text(announcement)
  end

  def when_i_type_the_output_fee_percentage(value)
    output_input.fill("")
    output_input.press_sequentially(value.to_s)
  end

  def then_nothing_is_announced_yet
    expect(service_fee_status.text_content).to eq("")
  end

  def then_the_service_fee_status_is_a_polite_live_region
    expect(service_fee_status).to have_attribute("aria-live", "polite")
    expect(service_fee_status).to have_attribute("aria-atomic", "true")
  end

  def and_it_is_silent_until_something_changes
    expect(service_fee_status.text_content).to eq("")
  end

  def and_the_output_fee_input_is_described_by_the_hint_and_the_status
    expect(output_input).to have_attribute("aria-describedby", "bands-service-fee-hint band-a-service-fee-status")
    expect(page.locator("#bands-service-fee-hint").text_content).to eq("Service fee is 100% minus the output fee.")
  end

  def when_i_save_the_contract
    page.get_by_role("button", name: "Save contract").click
  end

  def then_the_band_term_percentages_are(output:, service:)
    band_term = @contract.banded_fee_structure.band_terms.first

    expect(band_term.reload.output_fee_ratio).to eq(output)
    expect(band_term.service_fee_ratio).to eq(service)
  end

  def output_input
    page.get_by_label("Band A output fee percentage", exact: true)
  end

  def service_input
    page.get_by_label("Band A service fee percentage", exact: true)
  end

  def service_fee_status
    page.locator("#band-a-service-fee-status")
  end

  def edit_admin_finance_framework_agreement_contract_path
    "/admin/finance/contract-periods/#{@contract_period.year}/framework-agreements/#{@framework_agreement.id}/contracts/#{@contract.id}/edit"
  end
end
