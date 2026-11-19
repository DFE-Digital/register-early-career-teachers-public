RSpec.describe "Notify delivery receipts" do
  describe "POST /notify/delivery_receipts" do
    subject(:post_delivery_receipt) do
      post_delivery_receipt_request
      response
    end

    def post_delivery_receipt_request
      post notify_delivery_receipts_path, params: payload, headers:, as: :json
    end

    before { freeze_time }

    let(:token) { Rails.application.config.notify_delivery_receipts_bearer_token }
    let(:headers) { { "Authorization" => "Bearer #{token}" } }

    let(:notification_id) { SecureRandom.uuid }
    let(:template_id) { SecureRandom.uuid }
    let(:reference) { SecureRandom.uuid }
    let(:notification_type) { "email" }
    let(:status) { "permanent-failure" }

    let(:payload) do
      {
        id: notification_id,
        reference:,
        to: "test@example.com",
        status:,
        created_at: 10.minutes.ago.utc.iso8601,
        completed_at: 5.minutes.ago.utc.iso8601,
        sent_at: 8.minutes.ago.utc.iso8601,
        notification_type:,
        template_id:,
        template_version: 1,
      }
    end

    context "when delivery receipts are enabled",
            with_feature_flags: { enable_notify_delivery_receipts: true } do
      context "when the payload is valid" do
        it { is_expected.to have_http_status(:created) }

        it "creates a delivery receipt with the correct attributes" do
          expect { post_delivery_receipt }
            .to change(Notify::DeliveryReceipt, :count)
            .by(1)

          expect(Notify::DeliveryReceipt.last).to have_attributes(
            notification_id:,
            recipient: payload[:to],
            status: status.underscore,
            requested_at: 10.minutes.ago,
            completed_at: 5.minutes.ago,
            sent_at: 8.minutes.ago,
            notification_type:,
            template_id:,
            template_version: 1
          )
        end
      end

      context "when the optional values are missing" do
        before { payload.merge!(completed_at: nil, sent_at: nil) }

        it { is_expected.to have_http_status(:created) }

        it "creates a delivery receipt with the correct attributes" do
          expect { post_delivery_receipt }
            .to change(Notify::DeliveryReceipt, :count)
            .by(1)

          expect(Notify::DeliveryReceipt.last).to have_attributes(
            notification_id:,
            recipient: payload[:to],
            status: status.underscore,
            requested_at: 10.minutes.ago,
            completed_at: nil,
            sent_at: nil,
            notification_type:,
            template_id:,
            template_version: 1
          )
        end
      end

      context "when the payload is invalid" do
        let(:status) { "invalid-status" }

        it { is_expected.to have_http_status(:unprocessable_content) }

        it "does not create a delivery receipt" do
          expect { post_delivery_receipt }
            .not_to change(Notify::DeliveryReceipt, :count)
        end

        it "returns the validation errors in the response body" do
          expect(post_delivery_receipt.parsed_body).to eq(
            "errors" => { "status" => ["Choose a valid status"] }
          )
        end

        it "logs the errors in Sentry" do
          sentry_scope = instance_double(Sentry::Scope)
          allow(Sentry).to receive(:with_scope).and_yield(sentry_scope)
          allow(sentry_scope).to receive(:set_context)
          allow(Sentry).to receive(:capture_message)

          post_delivery_receipt

          expect(sentry_scope)
            .to have_received(:set_context)
            .with("errors", status: ["Choose a valid status"])
          expect(Sentry)
            .to have_received(:capture_message)
            .with("Failed to save delivery receipt")
        end
      end

      context "when the delivery receipt has already been recorded" do
        before { post_delivery_receipt_request }

        it { is_expected.to have_http_status(:unprocessable_content) }

        it "does not create a delivery receipt" do
          expect { post_delivery_receipt }
            .not_to change(Notify::DeliveryReceipt, :count)
        end

        it "returns the validation errors in the response body" do
          expect(post_delivery_receipt.parsed_body).to eq(
            "errors" => { "notification_id" => ["has already been taken"] }
          )
        end

        it "logs the errors in Sentry" do
          sentry_scope = instance_double(Sentry::Scope)
          allow(Sentry).to receive(:with_scope).and_yield(sentry_scope)
          allow(sentry_scope).to receive(:set_context)
          allow(Sentry).to receive(:capture_message)

          post_delivery_receipt

          expect(sentry_scope)
            .to have_received(:set_context)
            .with("errors", notification_id: ["has already been taken"])
          expect(Sentry)
            .to have_received(:capture_message)
            .with("Failed to save delivery receipt")
        end
      end

      context "when the bearer token is incorrect" do
        let(:token) { "incorrect-token" }

        it { is_expected.to have_http_status(:unauthorized) }

        it "does not create a delivery receipt" do
          expect { post_delivery_receipt }
            .not_to change(Notify::DeliveryReceipt, :count)
        end
      end

      context "when the bearer token is missing" do
        let(:headers) { {} }

        it { is_expected.to have_http_status(:unauthorized) }

        it "does not create a delivery receipt" do
          expect { post_delivery_receipt }
            .not_to change(Notify::DeliveryReceipt, :count)
        end
      end

      context "when no bearer token is configured",
              with_feature_flags: { notify_delivery_receipts_bearer_token: nil } do
        let(:token) { "any-token" }

        it { is_expected.to have_http_status(:unauthorized) }

        it "does not create a delivery receipt" do
          expect { post_delivery_receipt }
            .not_to change(Notify::DeliveryReceipt, :count)
        end
      end
    end

    context "when delivery receipts are disabled",
            with_feature_flags: { enable_notify_delivery_receipts: false } do
      it { is_expected.to have_http_status(:not_found) }

      it "does not create a delivery receipt" do
        expect { post_delivery_receipt }
          .not_to change(Notify::DeliveryReceipt, :count)
      end
    end
  end
end
