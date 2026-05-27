describe Schools::InductionTutorEmail do
  subject(:service) { described_class.new(school:) }

  let(:school) { FactoryBot.create(:school, gias_school:, induction_tutor_email:, induction_tutor_name:, induction_tutor_last_nominated_in: nil) }
  let(:gias_school) { FactoryBot.create(:gias_school, primary_contact_email:, secondary_contact_email:) }

  let(:induction_tutor_name) { "Griff Walnut" }
  let(:induction_tutor_email) { "griff@example.com" }
  let(:primary_contact_email) { "head@example.com" }
  let(:secondary_contact_email) { "bernard@example.com" }

  describe "#email" do
    it "returns the school induction tutor email" do
      expect(service.email).to eq(induction_tutor_email)
    end

    context "when the school induction tutor email is not set" do
      let(:induction_tutor_email) { nil }
      let(:induction_tutor_name) { nil }

      it "returns nil" do
        expect(service.email).to be_nil
      end
    end
  end

  describe "#email_or_gias_contact" do
    it "returns the school induction tutor email" do
      expect(service.email_or_gias_contact).to eq(induction_tutor_email)
    end

    context "when the school induction tutor email is not set" do
      let(:induction_tutor_email) { nil }
      let(:induction_tutor_name) { nil }

      it "returns the primary GIAS contact" do
        expect(service.email_or_gias_contact).to eq(primary_contact_email)
      end

      context "when the primary GIAS contact is not set" do
        let(:primary_contact_email) { nil }

        it "returns the secondary GIAS contact" do
          expect(service.email_or_gias_contact).to eq(secondary_contact_email)
        end

        context "when the secondary GIAS contact is not set" do
          let(:secondary_contact_email) { nil }

          it "returns nil" do
            expect(service.email_or_gias_contact).to be_nil
          end
        end
      end
    end
  end
end
