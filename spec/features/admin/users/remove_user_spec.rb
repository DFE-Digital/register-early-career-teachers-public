RSpec.describe "Admin removing a user" do
  include ActiveJob::TestHelper

  let!(:user) do
    FactoryBot.create(
      :user,
      name: "Daphne Blake",
      email: "daphne.blake@education.gov.uk",
      role: :admin
    )
  end

  before do
    sign_in_as_dfe_user(role: :user_manager)
  end

  scenario "removing a user" do
    given_i_am_on_the_users_page
    when_i_select_the_user
    then_i_should_see_the_user_details

    when_i_click_remove_user
    then_i_should_see_the_remove_user_confirmation_page

    when_i_confirm_without_checking_the_confirmation
    then_i_should_see_the_confirmation_error
    and_the_user_should_not_be_removed

    when_i_check_the_confirmation
    and_i_confirm_removal
    then_i_should_be_on_the_users_page
    and_i_should_see_the_success_message
    and_the_user_should_be_removed
    and_the_user_should_not_be_listed
    and_a_deletion_event_should_have_been_recorded
  end

private

  def given_i_am_on_the_users_page
    page.goto(admin_users_path)
  end

  def when_i_select_the_user
    page.get_by_role("link", name: user.name).click
  end

  def then_i_should_see_the_user_details
    expect(page.get_by_role("heading", name: user.name)).to be_visible
    expect(page.get_by_text(user.email)).to be_visible
  end

  def when_i_click_remove_user
    page.get_by_role("link", name: "Remove user").click
  end

  def then_i_should_see_the_remove_user_confirmation_page
    expect(
      page.get_by_role("heading", name: "Remove #{user.name} as a user")
    ).to be_visible

    expect(
      page.get_by_text(
        "If you remove this user, they will lose access to the admin console immediately."
      )
    ).to be_visible

    expect(
      page.get_by_label("I confirm I want to remove #{user.name} as a user")
    ).to be_visible

    expect(
      page.get_by_role("link", name: "Back", exact: true)
    ).to have_attribute("href", admin_user_path(user))

    expect(
      page.get_by_role(
        "link",
        name: "Cancel and go back to #{user.name}’s details",
        exact: true
      )
    ).to have_attribute("href", admin_user_path(user))

    expect(page.get_by_role("button", name: "Confirm")).to be_visible
  end

  def when_i_confirm_without_checking_the_confirmation
    page.get_by_role("button", name: "Confirm").click
  end

  def then_i_should_see_the_confirmation_error
    expect(page.locator(".govuk-error-summary"))
      .to have_text("Confirm you want to remove #{user.name} as a user")
  end

  def and_the_user_should_not_be_removed
    expect(User.exists?(user.id)).to be true
  end

  def when_i_check_the_confirmation
    page.get_by_label("I confirm I want to remove #{user.name} as a user").check
  end

  def and_i_confirm_removal
    perform_enqueued_jobs do
      page.get_by_role("button", name: "Confirm").click
    end
  end

  def then_i_should_be_on_the_users_page
    expect(page).to have_url(admin_users_path)
  end

  def and_i_should_see_the_success_message
    expect(
      page.get_by_text(
        "#{user.name} has been removed as a user and no longer has access to the admin console"
      )
    ).to be_visible
  end

  def and_the_user_should_be_removed
    expect(User.exists?(user.id)).to be false
  end

  def and_the_user_should_not_be_listed
    expect(
      page.get_by_role("table").get_by_role("link", name: user.name)
    ).not_to be_visible
  end

  def and_a_deletion_event_should_have_been_recorded
    event = Event.where(event_type: "dfe_user_deleted").last

    aggregate_failures do
      expect(event).to be_present
      expect(event.event_type).to eq("dfe_user_deleted")
      expect(event.heading).to eq("User #{user.name} removed")
      expect(event.metadata).to include(
        "name" => user.name,
        "email" => user.email,
        "role" => user.role
      )
    end
  end
end
