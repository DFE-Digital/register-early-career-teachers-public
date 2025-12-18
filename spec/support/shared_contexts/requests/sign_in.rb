RSpec.shared_context "sign in as non-DfE user" do
  before do
    sign_in_as(:appropriate_body_user, appropriate_body: FactoryBot.create(:appropriate_body))
  end
end

RSpec.shared_context "sign in as DfE user" do
  let(:user) { FactoryBot.create(:user, :admin) }

  before do
    sign_in_as(:dfe_user, user:)
  end
end

RSpec.shared_context "sign in as finance DfE user" do
  let(:user) { FactoryBot.create(:user, :finance) }

  before do
    sign_in_as(:dfe_user, user:)
  end
end
