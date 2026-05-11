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
      let(:attributes) { }

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

        expect(result.teacher_id).to eq(teacher.id)
        expect(result.school_id).to eq(school.id)
        expect(result.started_on).to eq(started_on)
        expect(result.email).to eq(email)
      end
    end

    context "when the action is 'update'" do
      it "sets the correct attributes on the object" do
        result = processor.process!(data_change:)

        expect(result.withdrawn_at).to eq(withdrawn_at)
        expect(result.withdrawal_reason).to eq "moved_school"
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
  end
end
