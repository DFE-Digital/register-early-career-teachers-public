RSpec.shared_examples 'a session user' do
  subject(:session_user) { described_class.new(last_active_at:, email:, **user_props) }

  let(:last_active_at) { 4.minutes.ago }

  describe '#email' do
    it 'returns the email of the user' do
      expect(session_user.email).to eql(email)
    end
  end

  describe '#expired?' do
    context 'when the last_active_at was less than the MAX_SESSION_IDLE_TIME ago' do
      let(:last_active_at) { (described_class::MAX_SESSION_IDLE_TIME - 1.minute).ago }

      it { is_expected.not_to be_expired }
    end

    context 'when the last_active_at was greater than the MAX_SESSION_IDLE_TIME ago' do
      let(:last_active_at) { (described_class::MAX_SESSION_IDLE_TIME + 1.minute).ago }

      it { is_expected.to be_expired }
    end
  end

  describe '#expires_at' do
    let(:last_active_at) { 1.minute.ago }

    it 'returns the time at which the user will be logged out if no new activity is registered' do
      expect(session_user.expires_at).to eql(last_active_at + described_class::MAX_SESSION_IDLE_TIME)
    end

    context 'when :last_active_at optional param is not passed in the initialisation' do
      subject(:session_user) { described_class.new(email:, **user_props) }

      it 'returns the maximum idle time from now' do
        expect(session_user.expires_at).to be_within(5.seconds).of(Time.current + described_class::MAX_SESSION_IDLE_TIME)
      end
    end
  end

  describe '#record_new_activity' do
    let(:right_now) { Time.current }

    it 'updates last_active_at' do
      expect { session_user.record_new_activity(right_now) }
        .to change(session_user, :last_active_at).from(last_active_at).to(right_now)
    end
  end
end
