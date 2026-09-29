describe Admin::DataFixes::Processor do
  subject(:processor) { described_class.new }

  let(:data_change) do
    {
      object_type: target_object.class.name,
      object_id: target_object.id,
      action:,
      attributes:,
    }
  end

  describe "#process!" do
    subject(:process!) { processor.process!(data_change:) }

    context "when the action is 'create'" do
      let(:action) { "create" }
      let(:target_object) { FactoryBot.build_stubbed(:ect_at_school_period) }
      let(:attributes) do
        "teacher_id,#{teacher.id},school_id,#{school.id},started_on,#{started_on},email,#{email}"
      end

      let!(:teacher) { FactoryBot.create(:teacher) }
      let!(:school) { FactoryBot.create(:school) }
      let(:started_on) { 1.day.ago.to_date }
      let(:email) { "mungo@example.com" }

      it "creates a new record" do
        expect { process! }.to change(ECTAtSchoolPeriod, :count).by(1)
      end

      it "sets the correct attributes on the object" do
        result = process!
        target_object = result.target_object

        expect(result).to be_success
        expect(target_object).to have_attributes(
          teacher_id: teacher.id,
          school_id: school.id,
          started_on:,
          email:
        )
      end

      context "when it sets an attribute with a value containing a comma" do
        let!(:target_object) { FactoryBot.build_stubbed(:appropriate_body) }
        let(:dfe_sign_in_organisation) { FactoryBot.create(:dfe_sign_in_organisation) }
        let(:attributes) do
          "name,\"A name containing, a comma\",dfe_sign_in_organisation_id,#{dfe_sign_in_organisation.id}"
        end

        it "creates a new record" do
          expect { process! }.to change(AppropriateBody, :count).by(1)
        end

        it "sets the correct attributes on the object" do
          result = process!
          target_object = result.target_object

          expect(result).to be_success
          expect(target_object).to have_attributes(
            name: "A name containing, a comma"
          )
        end
      end
    end

    context "when the action is 'update'" do
      let(:action) { "update" }
      let!(:target_object) { FactoryBot.create(:training_period) }
      let(:attributes) do
        "withdrawn_at,#{withdrawn_at.to_fs(:db)},withdrawal_reason,moved_school"
      end

      let(:withdrawn_at) { Time.zone.parse("2026-03-06 12:45:32 +0000") }

      it "does not create a new record" do
        expect { process! }.not_to change(TrainingPeriod, :count)
      end

      it "sets the correct attributes on the object" do
        result = process!
        target_object = result.target_object

        expect(result).to be_success
        expect(target_object).to have_attributes(
          withdrawn_at:,
          withdrawal_reason: "moved_school"
        )
      end

      context "when it updates an attribute with a value containing a comma" do
        let!(:target_object) { FactoryBot.create(:gias_school) }
        let(:attributes) do
          "name,\"A name containing, a comma\",postcode,SW1A 1AA"
        end

        it "does not create a new record" do
          expect { process! }.not_to change(School, :count)
        end

        it "sets the correct attributes on the object" do
          result = process!
          target_object = result.target_object

          expect(result).to be_success
          expect(target_object).to have_attributes(
            name: "A name containing, a comma",
            postcode: "SW1A 1AA"
          )
        end
      end

      context "when it attempts to update a attr_readonly attribute" do
        let!(:target_object) { FactoryBot.create(:declaration) }
        let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

        let(:attributes) { "delivery_partner_when_created_id,#{delivery_partner.id}" }

        it "returns the error in the result" do
          result = process!

          expect(result).not_to be_success
          expect(result.error).to be_a(ActiveRecord::ReadonlyAttributeError)
        end

        context "when update_readonly_attrs is set" do
          subject(:processor) { described_class.new(update_readonly_attrs: true) }

          it "updates the attribute correctly" do
            result = process!

            expect(result).to be_success
            expect(result.target_object.delivery_partner_when_created_id).to eq(delivery_partner.id)
          end
        end
      end
    end

    context "when the action is 'delete'" do
      let!(:target_object) { FactoryBot.create(:training_period) }
      let(:action) { "delete" }
      let(:attributes) { nil }

      it "deletes the object" do
        expect { process! }.to change(TrainingPeriod, :count).by(-1)
      end

      context "and the record cannot be destroyed" do
        let!(:declaration) do
          FactoryBot.create(:declaration, :payable, training_period: target_object)
        end

        it "returns the error in the result" do
          result = process!

          expect(result).not_to be_success
          expect(result.error).to be_a(ActiveRecord::RecordNotDestroyed)
        end
      end
    end

    context "when the action is 'unknown'" do
      let!(:target_object) { FactoryBot.create(:training_period) }
      let(:action) { "unknown" }
      let(:attributes) { nil }

      it "returns the error in the result" do
        result = process!

        expect(result).not_to be_success
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to eq("Unknown action 'unknown'")
      end
    end

    context "when the data change is blank" do
      let(:data_change) { {} }

      it "returns a successful no-op result" do
        result = process!

        expect(result).to be_success
        expect(result.target_object).to be_nil
        expect(result.action).to be_nil
        expect(result.error).to be_nil
      end
    end
  end
end
