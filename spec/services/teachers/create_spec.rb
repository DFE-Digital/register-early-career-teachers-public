require "rails_helper"

RSpec.describe Teachers::Create do
  let(:trn) { "1234567" }
  let(:trs_first_name) { "John" }
  let(:trs_last_name) { "Doe" }
  let(:trs_qts_awarded_on) { Date.new(2020, 1, 1) }
  let(:author) do
    Sessions::Users::AppropriateBodyUser.new(
      name: 'A user',
      email: 'ab_user@something.org',
      dfe_sign_in_user_id: SecureRandom.uuid,
      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id
    )
  end
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  subject(:service) do
    described_class.new(
      trn:,
      trs_first_name:,
      trs_last_name:,
      trs_qts_awarded_on:,
      author:,
      appropriate_body:
    )
  end

  describe "#create_teacher" do
    it "creates a new teacher record" do
      expect { service.create_teacher }.to change(Teacher, :count).by(1)
    end

    it "sets the correct attributes on the teacher" do
      teacher = service.create_teacher

      expect(teacher.trn).to eq(trn)
      expect(teacher.trs_first_name).to eq(trs_first_name)
      expect(teacher.trs_last_name).to eq(trs_last_name)
      expect(teacher.trs_qts_awarded_on).to eq(trs_qts_awarded_on)
    end

    it "records a teacher_record_created event" do
      expect(Events::Record).to receive_message_chain(:new, :record_event!)

      service.create_teacher
    end

    context "when author or appropriate_body is missing" do
      let(:author) { nil }

      it "does not record an event" do
        expect(Events::Record).not_to receive(:new)

        service.create_teacher
      end

      it "still creates the teacher record" do
        expect { service.create_teacher }.to change(Teacher, :count).by(1)
      end
    end
  end
end
