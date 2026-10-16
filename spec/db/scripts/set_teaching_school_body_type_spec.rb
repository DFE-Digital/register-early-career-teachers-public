require Rails.root.join("db/scripts/set_teaching_school_body_type")

RSpec.describe SetTeachingSchoolBodyType do
  describe "#call" do
    describe "appropriate body periods linked to a school" do
      let(:provisioning_school) { FactoryBot.create(:school) }

      let(:appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          teaching_school_hub:,
                          provisioning_school:)
      end

      context "when a period is only linked to a school" do
        let(:teaching_school_hub) { nil }

        it "sets the body type to teaching_school" do
          expect(appropriate_body_period).to be_teaching_school_hub
          described_class.new.call
          expect(appropriate_body_period.reload).to be_teaching_school
        end
      end

      context "when a period is linked to more than a school" do
        let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub) }

        it "is unchanged" do
          expect(appropriate_body_period).to be_teaching_school_hub
          described_class.new.call
          expect(appropriate_body_period.reload).to be_teaching_school_hub
        end
      end
    end

    context "when a period has no school link" do
      let(:la) { FactoryBot.create(:appropriate_body_period, :local_authority) }
      let(:nb) { FactoryBot.create(:appropriate_body_period, :national) }

      it "is unchanged" do
        expect(la).to be_local_authority
        expect(nb).to be_national
        described_class.new.call
        expect(la.reload).to be_local_authority
        expect(nb.reload).to be_national
      end
    end
  end
end
