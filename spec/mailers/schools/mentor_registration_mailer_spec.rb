RSpec.describe Schools::MentorRegistrationMailer, type: :mailer do
  let(:teacher) { FactoryBot.create(:teacher, corrected_name: "Marvin Fuller") }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, email: "mentor@example.com") }
  let(:mail) { described_class.with(mentor_at_school_period:).confirmation }

  it "renders the headers" do
    expect(mail.subject).to eq("#{described_class::SUBJECT_PREFIX} #{mentor_at_school_period.school.name}")
    expect(mail.to).to eq([mentor_at_school_period.email])
  end

  it "renders the body" do
    expect(mail.body).to include("Hello Marvin Fuller,")
    expect(mail.body).to include(mentor_at_school_period.school.name)
    expect(mail.body).to include("Mentors guidance")
    expect(mail.body).to include(described_class::MENTORS_GUIDANCE_URL)
    expect(mail.body).to include(described_class::PRIVACY_NOTICE_URL)
  end
end
