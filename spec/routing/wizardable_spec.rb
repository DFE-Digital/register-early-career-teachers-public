RSpec.describe 'Wizardable routes' do
  before do
    allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
  end

  it 'creates GET and POST routes for each step' do
    expect(get: '/school/register-mentor/find-mentor')
      .to route_to(controller: 'schools/register_mentor_wizard', action: 'new')
    expect(post: '/school/register-mentor/find-mentor')
      .to route_to(controller: 'schools/register_mentor_wizard', action: 'create')

    # TODO: move under "school" path
    expect(get: '/schools/register-ect/find-ect')
      .to route_to(controller: 'schools/register_ect_wizard', action: 'new')
    expect(post: '/schools/register-ect/find-ect')
      .to route_to(controller: 'schools/register_ect_wizard', action: 'create')
  end
end
