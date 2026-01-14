RSpec.describe Schools::ECTRegistrationMailer, type: :mailer do
  let(:teacher) { FactoryBot.create(:teacher, corrected_name: "The Flash") }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, email: "flash@example.com") }

  describe "#provider_led_confirmation" do
    let(:mail) { described_class.with(ect_at_school_period:).provider_led_confirmation }

    it "renders the headers" do
      expect(mail.subject).to eq(described_class::SUBJECT)
      expect(mail.to).to eq([ect_at_school_period.email])
    end

    it "renders the body" do
      expect(mail.body).to include("Hello The Flash,")
      expect(mail.body).to include(ect_at_school_period.school.name)
      expect(mail.body).to include("training provider")
      expect(mail.body).to include(described_class::ECT_GUIDANCE_URL)
      expect(mail.body).to include(described_class::PRIVACY_NOTICE_URL)
    end
  end

  describe "#school_led_confirmation" do
    let(:mail) { described_class.with(ect_at_school_period:).school_led_confirmation }

    it "renders the headers" do
      expect(mail.subject).to eq(described_class::SUBJECT)
      expect(mail.to).to eq([ect_at_school_period.email])
    end

    it "renders the body" do
      expect(mail.body).to include("Hello The Flash,")
      expect(mail.body).to include(ect_at_school_period.school.name)
      expect(mail.body).to include("school-led")
      expect(mail.body).to include(described_class::ECT_GUIDANCE_URL)
      expect(mail.body).to include(described_class::PRIVACY_NOTICE_URL)
    end
  end
end
