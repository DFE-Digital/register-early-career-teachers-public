RSpec.describe Notify::Trackable do
  subject(:deliver_email) do
    trackable_mailer.test_email(reference:).deliver_now
  end

  let(:trackable_mailer) do
    stub_const(
      "TestMailer",
      Class.new(ApplicationMailer) do
        include Notify::Trackable

        # Ideally we would override `body` explicitly, but `view_mail` calls
        # `mail` directly without forwarding headers
        # https://github.com/dxw/mail-notify/blob/main/lib/mail/notify/mailer.rb#L85
        # so we need to define some fixture mailer views to avoid
        # `MissingTemplate` errors.
        prepend_view_path "spec/fixtures/mailer_views"

        def test_email(reference:)
          view_mail(
            ApplicationMailer::NOTIFY_TEMPLATE_ID,
            to: "test@example.com",
            subject: "Test email with reference",
            reference:
          )
        end
      end
    )
  end

  context "when delivery receipts are enabled",
          with_feature_flags: { enable_notify_delivery_receipts: true } do
    context "when the email has a reference" do
      let(:reference) { "test-reference" }

      it "creates a `Notify::Outbound` record" do
        expect { deliver_email }
          .to change(Notify::Outbound, :count)
          .by(1)

        expect(Notify::Outbound.last).to have_attributes(
          reference: "test-reference",
          mailer: "TestMailer",
          mailer_action: "test_email"
        )
      end
    end

    context "when the email does not have a reference" do
      let(:reference) { nil }

      it "does not create a `Notify::Outbound` record" do
        expect { deliver_email }.not_to change(Notify::Outbound, :count)
      end
    end

    context "when there is an error creating the `Notify::Outbound` record" do
      let(:reference) { "test-reference" }

      before do
        allow(Notify::Outbound).to receive(:create!).and_raise(StandardError)
      end

      it "does not create a `Notify::Outbound` record" do
        expect { deliver_email }.not_to change(Notify::Outbound, :count)
      end

      it "does not raise an error" do
        expect { deliver_email }.not_to raise_error
      end

      it "logs the error in Sentry" do
        allow(Sentry).to receive(:capture_exception)

        deliver_email

        expect(Sentry)
          .to have_received(:capture_exception)
          .with(instance_of(StandardError))
      end
    end
  end

  context "when delivery receipts are disabled",
          with_feature_flags: { enable_notify_delivery_receipts: false } do
    context "when the email has a reference" do
      let(:reference) { "test-reference" }

      it "does not create a `Notify::Outbound` record" do
        expect { deliver_email }.not_to change(Notify::Outbound, :count)
      end
    end

    context "when the email does not have a reference" do
      let(:reference) { nil }

      it "does not create a `Notify::Outbound` record" do
        expect { deliver_email }.not_to change(Notify::Outbound, :count)
      end
    end
  end
end
