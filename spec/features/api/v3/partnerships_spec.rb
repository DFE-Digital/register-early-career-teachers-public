RSpec.describe "Partnerships APIs" do
  scenario "retrieving partnerships" do
    lead_provider = create(:lead_provider)

    lead_provider_delivery_partnership1 = create(:lead_provider_delivery_partnership, lead_provider:)
    create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership1)

    lead_provider_delivery_partnership2 = create(:lead_provider_delivery_partnership, lead_provider:)
    create(:school_partnership, lead_provider_delivery_partnership: lead_provider_delivery_partnership2)

    # We're going to fight with Playwright here to make a request without using the browser.
    page.driver.get(api_v3_partnerships_path, { "Authorization" => "Bearer #{APIToken.create_with_random_token!(lead_provider:)}" })
  end
end
