shared_context 'fake session manager for non-DfE user' do
  let(:user) { FactoryBot.create(:user) }
  let(:session_manager) { instance_double(Sessions::Manager, current_user: fake_user) }
  let(:fake_user) { double(Sessions::User, email: 'admin@example.org', name: 'sample admin', dfe_user?: false, user_type: :school_user) }

  before do
    allow(Sessions::Manager).to receive(:new).and_return(session_manager)
  end
end

shared_context 'fake session manager for DfE user' do
  let(:session_manager) { instance_double(Sessions::Manager, current_user: fake_user) }
  let(:fake_user) { double(Sessions::User, email: 'admin@example.org', name: 'sample admin', dfe_user?: true, user_type: :dfe_staff_user) }

  before do
    allow(Sessions::Manager).to receive(:new).and_return(session_manager)
  end
end
