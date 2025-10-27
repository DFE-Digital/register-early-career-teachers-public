RSpec.describe 'Access denial', :enable_schools_interface do
  context 'when the user has not completed onboarding with DfE Sign In' do
    # DSI response includes neither UUID and URN
    before do
      sign_in_as_unrecognised_user(organisation_id: nil, organisation_urn: nil)
    end

    scenario 'they see the access denied page' do
      then_i_see_the_access_denied_page
      and_i_see_a_link_to_my_dfe_sign_in_profile
      expect(page.content).to include('You must be a user approved by an organisation to access this service.')
      expect(page.content).not_to include('Invalid Organisation')
    end
  end

  context 'when the user is from an unrecognised organisation' do
    # DSI response only includes unrecognised UUID
    before do
      sign_in_as_unrecognised_user(organisation_urn: nil)
    end

    scenario 'they see the access denied page' do
      then_i_see_the_access_denied_page
      and_i_see_my_organisation_name
      and_i_see_a_link_to_sign_in
      and_i_see_a_link_to_my_dfe_sign_in_profile
    end
  end

  context 'when the user is from a unrecognised school' do
    # DSI response includes both unrecognised UUID and URN
    before do
      sign_in_as_unrecognised_user
    end

    scenario 'they see the access denied page' do
      then_i_see_the_access_denied_page
      and_i_see_my_organisation_name
      and_i_see_a_link_to_sign_in
      and_i_see_a_link_to_my_dfe_sign_in_profile
    end
  end

  context 'when the user is from a valid school which was formerly an AB' do
    let(:school) { FactoryBot.create(:school) }

    # DSI response includes a valid URN
    before do
      sign_in_as_unrecognised_user(organisation_urn: school.urn)
    end

    scenario 'they see the access denied page' do
      then_i_see_the_access_denied_page
      and_i_see_my_organisation_name
      and_i_see_a_link_to_sign_in
      and_i_see_a_link_to_my_dfe_sign_in_profile
    end
  end

private

  def then_i_see_the_access_denied_page
    expect(page).to have_path('/access-denied')
    expect(page.title).to include('Access denied')
  end

  def and_i_see_a_link_to_sign_in
    expect(page.content).to have_link('Go back and try again', href: '/')
  end

  def and_i_see_a_link_to_my_dfe_sign_in_profile
    expect(page.content).to have_link('Go to DfE Sign-In profile (opens in new tab)', href: "https://test-profile.signin.education.gov.uk")
  end

  def and_i_see_my_organisation_name
    expect(page.content).to include('You have tried to sign in to this service with Invalid Organisation.')
    expect(page.content).to include('contact the approver at Invalid Organisation to request access')
  end
end
