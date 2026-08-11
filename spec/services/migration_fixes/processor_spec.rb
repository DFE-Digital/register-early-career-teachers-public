describe MigrationFixes::Processor do
  subject(:processor) { described_class.new }

  let!(:target_object) { FactoryBot.create(:training_period) }
  let(:action) { "update" }
  let(:withdrawn_at) { Time.zone.parse("2026-03-06 12:45:32 +0000") }
  let(:attributes) { "withdrawn_at,#{withdrawn_at.to_fs(:db)},withdrawal_reason,moved_school" }

  let(:data_change) do
    {
      object_type: target_object.class.name,
      object_id: target_object.id,
      action:,
      attributes:,
    }
  end

  describe "#process!" do
    context "when the action is 'create'" do
      let!(:teacher) { FactoryBot.create(:teacher) }
      let!(:school) { FactoryBot.create(:school) }
      let(:started_on) { 1.day.ago.to_date }
      let(:email) { "mungo@example.com" }
      let(:action) { "create" }
      let(:data_change) do
        {
          object_type: "ECTAtSchoolPeriod",
          object_id: nil,
          action: "create",
          attributes: "teacher_id,#{teacher.id},school_id,#{school.id},started_on,#{started_on},email,#{email}"
        }
      end

      it "creates a new record" do
        expect {
          processor.process!(data_change:)
        }.to change(ECTAtSchoolPeriod, :count).by(1)
      end

      it "sets the correct attributes on the object" do
        result = processor.process!(data_change:)
        target_object = result.target_object

        expect(result.success?).to be(true)
        expect(target_object.teacher_id).to eq(teacher.id)
        expect(target_object.school_id).to eq(school.id)
        expect(target_object.started_on).to eq(started_on)
        expect(target_object.email).to eq(email)
      end
    end

    context "when the action is 'update'" do
      it "sets the correct attributes on the object" do
        result = processor.process!(data_change:)
        target_object = result.target_object

        expect(result.success?).to be(true)
        expect(target_object.withdrawn_at).to eq(withdrawn_at)
        expect(target_object.withdrawal_reason).to eq("moved_school")
      end

      context "when it attempts to update a attr_readonly attribute" do
        let!(:target_object) { FactoryBot.create(:declaration) }
        let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

        let(:attributes) { "delivery_partner_when_created_id,#{delivery_partner.id}" }

        it "returns the error in the result" do
          result = processor.process!(data_change:)

          expect(result.success?).to be(false)
          expect(result.error).to be_a(ActiveRecord::ReadonlyAttributeError)
        end

        context "when update_readonly_attrs is set" do
          subject(:processor) { described_class.new(update_readonly_attrs: true) }

          it "updates the attribute correctly" do
            result = processor.process!(data_change:)

            expect(result.success?).to be(true)
            expect(result.target_object.delivery_partner_when_created_id).to eq(delivery_partner.id)
          end
        end
      end
    end

    context "when the action is 'delete'" do
      let(:action) { "delete" }
      let(:attributes) { nil }

      it "deletes the object" do
        expect {
          processor.process!(data_change:)
        }.to change(TrainingPeriod, :count).by(-1)
      end
    end

    context "when the action is unknown" do
      let(:action) { "unknown" }

      it "returns the error in the result" do
        result = processor.process!(data_change:)

        expect(result.success?).to be(false)
        expect(result.error).to be_a(ArgumentError)
        expect(result.error.message).to eq("Unknown action 'unknown'")
      end
    end

    context "when the data change is blank" do
      it "returns a successful no-op result" do
        result = processor.process!(data_change: {})

        expect(result).to be_a(MigrationFixes::Result)
        expect(result).to be_success
        expect(result.data_change).to eq({})
        expect(result.target_object).to be_nil
        expect(result.error).to be_nil
      end
    end
  end
end
