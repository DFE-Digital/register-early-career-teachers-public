RSpec.describe 'Authentication', :enable_schools_interface do
  context 'when the user is unrecognised' do
    before { sign_in_as_unrecognised_user }

    scenario 'they see the access denied page' do
      expect(page).to have_path('/access-denied')
      expect(page.title).to include('Access denied')
      expect(page.content).to include('Invalid Organisation is not set up to use this service')
    end
  end
end
