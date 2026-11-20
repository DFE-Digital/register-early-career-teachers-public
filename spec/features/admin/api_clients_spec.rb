RSpec.describe "Admin API clients", :js do
  before do
    sign_in_as_dfe_user(role: :product_team)
    @client = FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform")
  end

  scenario "copying a new client secret" do
    when_i_rotate_a_client_secret
    and_i_copy_the_client_secret
    then_the_client_secret_is_on_the_clipboard
  end

  def when_i_rotate_a_client_secret
    page.goto(new_admin_api_client_client_secret_rotation_path(@client))
    page.get_by_role("button", name: "Rotate client secret").click
  end

  def and_i_copy_the_client_secret
    page.context.grant_permissions(%w[clipboard-read clipboard-write])
    page.get_by_role("button", name: "Copy client secret").click
  end

  def then_the_client_secret_is_on_the_clipboard
    expect(page.get_by_role("status").filter(hasText: "Client secret copied")).to have_count(1)
    expect(page.evaluate("navigator.clipboard.readText()")).to eq(page.get_by_label("Client secret").input_value)
  end
end
