RSpec.shared_context 'sign in as non-DfE user' do
  before do
    sign_in_as(:appropriate_body_user, appropriate_body: FactoryBot.create(:appropriate_body))
  end
end

RSpec.shared_context 'sign in as DfE user' do
  before do
    sign_in_as(:dfe_user, user: FactoryBot.create(:user, :admin))
  end
end
