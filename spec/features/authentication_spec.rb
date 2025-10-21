RSpec.describe 'Authentication', :enable_schools_interface do
  context 'when the user is unrecognised' do
    before { sign_in_as_unrecognised_user }

    scenario 'they see the access denied page' do
      expect(page).to have_path('/access-denied')
      expect(page.title).to include('User not found')
      expect(page.content).to include('Invalid Organisation').and include('is not the correct organisation')
      expect(page.content).to have_link('go to DSI and sign out', href: "https://test-services.signin.education.gov.uk/my-services")
    end
  end
end
