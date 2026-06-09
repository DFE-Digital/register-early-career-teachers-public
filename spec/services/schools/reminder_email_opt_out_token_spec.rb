RSpec.describe Schools::ReminderEmailOptOutToken do
  before do
    allow(Rails.application.config)
      .to receive(:school_reminder_email_opt_out_token_secret)
      .and_return("test-secret")
  end

  describe ".generate_for" do
    it "returns a 64-character hex string" do
      token = described_class.generate_for(school_id: 42)
      expect(token).to match(/\A[0-9a-f]{64}\z/)
    end

    it "is deterministic for the same school id" do
      a = described_class.generate_for(school_id: 42)
      b = described_class.generate_for(school_id: 42)
      expect(a).to eq(b)
    end

    it "differs for different school ids" do
      a = described_class.generate_for(school_id: 42)
      b = described_class.generate_for(school_id: 43)
      expect(a).not_to eq(b)
    end

    it "differs when the secret changes" do
      original = described_class.generate_for(school_id: 42)
      allow(Rails.application.config)
        .to receive(:school_reminder_email_opt_out_token_secret)
        .and_return("a-different-secret")
      rotated = described_class.generate_for(school_id: 42)
      expect(rotated).not_to eq(original)
    end

    it "raises when the secret is not configured" do
      allow(Rails.application.config)
        .to receive(:school_reminder_email_opt_out_token_secret)
        .and_return(nil)
      expect { described_class.generate_for(school_id: 42) }
        .to raise_error(described_class::MissingSecretError, /SCHOOL_REMINDER_EMAIL_OPT_OUT_TOKEN_SECRET/)
    end
  end

  describe ".valid?" do
    let(:school_id) { 42 }
    let(:token)     { described_class.generate_for(school_id:) }

    it "returns true for the matching school id and token" do
      expect(described_class.valid?(school_id:, token:)).to be(true)
    end

    it "returns false for a blank token" do
      expect(described_class.valid?(school_id:, token: nil)).to be(false)
      expect(described_class.valid?(school_id:, token: "")).to be(false)
    end

    it "returns false when the token belongs to a different school id" do
      other_token = described_class.generate_for(school_id: 99)
      expect(described_class.valid?(school_id:, token: other_token)).to be(false)
    end

    it "returns false when the token has been tampered with" do
      tampered = token.dup
      tampered[0] = (tampered[0] == "0" ? "1" : "0")
      expect(described_class.valid?(school_id:, token: tampered)).to be(false)
    end

    it "returns false for a wrong token of the same length" do
      wrong = "0" * 64
      expect(described_class.valid?(school_id:, token: wrong)).to be(false)
    end
  end

  describe ".token_sql" do
    it "produces SQL that reproduces the Ruby token for the same school id" do
      sql_token = ActiveRecord::Base.connection.select_value("SELECT #{described_class.token_sql(school_id_sql: '42')}")

      expect(sql_token).to eq(described_class.generate_for(school_id: 42))
    end

    it "raises when the secret is not configured" do
      allow(Rails.application.config)
        .to receive(:school_reminder_email_opt_out_token_secret)
        .and_return(nil)

      expect { described_class.token_sql(school_id_sql: "schools.id") }
        .to raise_error(described_class::MissingSecretError)
    end
  end
end
