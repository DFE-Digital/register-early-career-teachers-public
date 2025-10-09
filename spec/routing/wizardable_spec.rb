RSpec.describe 'Wizardable routes', :enable_schools_interface do
  it 'creates GET and POST routes for each step' do
    expect(get: '/school/register-mentor/find-mentor')
      .to route_to(controller: 'schools/register_mentor_wizard', action: 'new')
    expect(post: '/school/register-mentor/find-mentor')
      .to route_to(controller: 'schools/register_mentor_wizard', action: 'create')

    expect(get: '/school/register-ect/find-ect')
      .to route_to(controller: 'schools/register_ect_wizard', action: 'new')
    expect(post: '/school/register-ect/find-ect')
      .to route_to(controller: 'schools/register_ect_wizard', action: 'create')
  end
end
