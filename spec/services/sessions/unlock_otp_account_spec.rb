RSpec.describe Sessions::UnlockOTPAccount do
  subject(:service) { described_class.new(author:, user: locked_user) }

  let(:author_user) { FactoryBot.create(:user, email: "unlocker@education.gov.uk") }
  let(:author) { Sessions::Users::DfEUser.new(email: author_user.email) }
  let(:locked_user) { FactoryBot.create(:user, otp_failed_attempts: 10, otp_locked_at: Time.zone.now) }

  describe "#unlock" do
    it "resets failed attempts" do
      expect { service.unlock }.to change { locked_user.reload.otp_failed_attempts }.from(10).to(0)
    end

    it "clears the locked timestamp" do
      expect { service.unlock }.to change { locked_user.reload.otp_locked_at }.to(nil)
    end

    it "records an unlock event" do
      freeze_time do
        service.unlock

        event = Event.where(event_type: "otp_account_unlocked").sole
        expect(event.user_id).to eq(locked_user.id)
        expect(event.metadata).to eq(
          "otp_failed_attempts" => [10, 0],
          "otp_locked_at" => [Time.zone.now.as_json, nil]
        )
      end
    end

    it "restores access" do
      otp = Sessions::OneTimePassword.new(user: locked_user)
      code = otp.generate

      service.unlock

      expect(otp.verify(code:)).to be true
    end
  end
end
