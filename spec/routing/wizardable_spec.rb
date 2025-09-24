RSpec.describe 'Wizardable routes' do
  it 'creates GET and POST routes for each step' do
    expect(get: '/school/register-mentor/find-mentor')
      .to route_to(controller: 'schools/register_mentor_wizard', action: 'new')
    expect(post: '/school/register-mentor/find-mentor')
      .to route_to(controller: 'schools/register_mentor_wizard', action: 'create')
  end
end
