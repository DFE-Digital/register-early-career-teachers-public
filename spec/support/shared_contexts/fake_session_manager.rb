shared_context 'fake session manager for non-DfE user' do
  let(:user) { FactoryBot.create(:user) }
  let(:session_manager) { instance_double(Sessions::SessionManager, current_user: fake_user) }
  let(:fake_user) { double(Sessions::User, email: 'admin@example.org', name: 'sample admin', dfe_user?: false) }

  before do
    allow(Sessions::SessionManager).to receive(:new).and_return(session_manager)
  end
end

shared_context 'fake session manager for DfE user' do
  let(:session_manager) { instance_double(Sessions::SessionManager, current_user: fake_user) }
  let(:fake_user) { double(Sessions::User, email: 'admin@example.org', name: 'sample admin', dfe_user?: true) }

  before do
    allow(Sessions::SessionManager).to receive(:new).and_return(session_manager)
  end
end
