RSpec.describe Sessions::OneTimePassword do
  subject(:service) { Sessions::OneTimePassword.new(user:) }

  let(:user) { FactoryBot.create(:user) }

  describe "#generate" do
    it "returns a OTP code" do
      expect(service.generate).to match(/\A\d{6}\z/)
    end

    it "sets a secret on the user" do
      expect { service.generate }.to(change { user.otp_secret })
    end

    it "does not reset failed attempts" do
      user.update!(otp_failed_attempts: 4)

      expect { service.generate }.not_to(change { user.reload.otp_failed_attempts })
    end

    it "does not unlock the account" do
      user.update!(otp_locked_at: Time.zone.now)

      expect { service.generate }.not_to(change { user.reload.otp_locked_at })
    end
  end

  describe "#generate_and_send_code" do
    it "calls generate" do
      expect(service).to receive(:generate).once
      service.generate_and_send_code
    end

    it "sends an email to the user" do
      allow(service).to receive(:generate).and_return("123456")

      expect {
        service.generate_and_send_code
      }.to have_enqueued_mail(OTPMailer, :otp_code_email).with(params: { recipient_email: user.email,
                                                                         recipient_name: user.name,
                                                                         code: "123456" },
                                                               args: [])
    end
  end

  describe "#verify" do
    context "when the code is valid" do
      it "returns true" do
        code = service.generate
        expect(service.verify(code:)).to be true
      end

      it "updates the otp_verified_at timestamp" do
        code = service.generate
        expect { service.verify(code:) }.to(change { user.otp_verified_at })
      end

      it "resets failed attempts" do
        user.update!(otp_failed_attempts: 3)
        code = service.generate

        expect { service.verify(code:) }.to change { user.reload.otp_failed_attempts }.from(3).to(0)
      end
    end

    context "when the code has already been verified" do
      it "returns false" do
        code = service.generate
        service.verify(code:)

        expect(service.verify(code:)).to be false
      end

      it "does not update the otp_verified_at timestamp" do
        code = service.generate
        service.verify(code:)

        expect { service.verify(code:) }.not_to(change { user.otp_verified_at })
      end
    end

    context "when the code has expired" do
      it "returns false" do
        code = service.generate
        travel_to 11.minutes.from_now do
          expect(service.verify(code:)).to be false
        end
      end

      it "does not update the otp_verified_at timestamp" do
        code = service.generate

        travel_to 11.minutes.from_now do
          expect { service.verify(code:) }.not_to(change { user.otp_verified_at })
        end
      end
    end

    context "when the code is invalid" do
      let(:code) { service.generate }
      let(:invalid_code) { ((code.to_i + 1) % 1_000_000).to_s.rjust(6, "0") }

      before do
        allow(Events::Record).to receive(:record_otp_account_locked_event!)
      end

      it "increments failed attempts" do
        expect { service.verify(code: invalid_code) }.to change { user.reload.otp_failed_attempts }.from(0).to(1)
      end

      it "does not record a locked event before the 10th failed attempt" do
        service.verify(code: invalid_code)

        expect(Events::Record).not_to have_received(:record_otp_account_locked_event!)
      end

      it "locks the account on the 10th failed attempt" do
        user.update!(otp_failed_attempts: 9)

        freeze_time do
          expect { service.verify(code: invalid_code) }
            .to change { user.reload.otp_locked_at }
            .from(nil)
            .to(Time.zone.now)

          expect(user.otp_failed_attempts).to eq(10)
        end
      end

      it "records a locked event on the 10th failed attempt" do
        user.update!(otp_failed_attempts: 9)

        freeze_time do
          service.verify(code: invalid_code)

          expect(Events::Record).to have_received(:record_otp_account_locked_event!).with(
            user:,
            modifications: {
              "otp_failed_attempts" => [9, 10],
              "otp_locked_at" => [nil, Time.zone.now],
            }
          )
        end
      end
    end

    context "when the account is locked" do
      it "returns false" do
        code = service.generate
        user.update!(otp_locked_at: Time.zone.now)

        expect(service.verify(code:)).to be false
      end

      it "does not update the otp_verified_at timestamp" do
        code = service.generate
        user.update!(otp_locked_at: Time.zone.now)

        expect { service.verify(code:) }.not_to(change { user.reload.otp_verified_at })
      end

      it "does not increment failed attempts when the account is locked" do
        code = service.generate
        user.update!(otp_failed_attempts: 10, otp_locked_at: Time.zone.now)

        expect { service.verify(code:) }.not_to change { user.reload.otp_failed_attempts }
      end
    end
  end
end
