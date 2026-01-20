RSpec.describe Schools::InductionTutorConfirmationMailer, type: :mailer do
  let(:school) do
    FactoryBot.create(
      :school,
      :with_induction_tutor,
      induction_tutor_name: "The Flash",
      induction_tutor_email: "flash@fast.com"
    )
  end

  describe "#confirmation" do
    let(:mail) { described_class.with(school:).confirmation }

    it "renders the headers" do
      expect(mail.subject).to eq("#{described_class::SUBJECT_PREFIX} #{school.name}")
      expect(mail.to).to eq([school.induction_tutor_email])
    end

    it "renders the body" do
      expect(mail.body).to include("Hello The Flash,")
      expect(mail.body).to include(school.name)
      expect(mail.body).to include(described_class::SETUP_ECTE_GUIDANCE_URL)
      expect(mail.body).to include(described_class::PRIVACY_NOTICE_URL)
      expect(mail.body).to include(described_class::REGISTER_ECT_SERVICE_URL)
    end
  end
end
