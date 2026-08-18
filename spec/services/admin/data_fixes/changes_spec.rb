RSpec.describe Admin::DataFixes::Changes do
  subject(:changes) { described_class.new(parsed_rows:) }

  describe "#process" do
    subject(:process) { changes.process }

    context "when none of the changes are valid" do
      let!(:teacher) { FactoryBot.create(:teacher) }

      let(:parsed_rows) do
        [
          {
            "object_type" => "Teacher",
            "object_id" => teacher.id.to_s,
            "action" => "update",
            "attributes" => "trn,,trs_first_name,New Name"
          },
          {
            "object_type" => "ECTAtSchoolPeriod",
            "object_id" => "99",
            "action" => "delete",
            "attributes" => ""
          }
        ]
      end

      it { is_expected.to be_falsey }

      it "validates the data changes are successful" do
        process
        expect(changes.errors.count).to eq(2)
        expect(changes.errors[:base].first)
          .to match(/Row 1: Validation failed: TRN/)
        expect(changes.errors[:base].second)
          .to match(/Row 2: Couldn't find ECTAtSchoolPeriod/)
      end
    end

    context "when only some of the changes are valid" do
      let!(:teacher) { FactoryBot.create(:teacher) }
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }

      let(:parsed_rows) do
        [
          {
            "object_type" => "Teacher",
            "object_id" => teacher.id.to_s,
            "action" => "update",
            "attributes" => "trn,123456,trs_first_name,New Name"
          },
          {
            "object_type" => "ECTAtSchoolPeriod",
            "object_id" => ect_at_school_period.id.to_s,
            "action" => "destroy",
            "attributes" => ""
          }
        ]
      end

      it { is_expected.to be_falsey }

      it "validates the data changes are successful" do
        process
        expect(changes.errors.count).to eq(1)
        expect(changes.errors[:base].first)
          .to match(/Row 2: Unknown action 'destroy'/)
      end
    end

    context "when all the changes are valid" do
      let!(:teacher) { FactoryBot.create(:teacher) }
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }

      let(:parsed_rows) do
        [
          {
            "object_type" => "Teacher",
            "object_id" => teacher.id.to_s,
            "action" => "update",
            "attributes" => "trn,123456,trs_first_name,New Name"
          },
          {
            "object_type" => "ECTAtSchoolPeriod",
            "object_id" => ect_at_school_period.id.to_s,
            "action" => "delete",
            "attributes" => ""
          }
        ]
      end

      it { is_expected.to be_truthy }

      it "has no errors" do
        process
        expect(changes.errors).to be_empty
      end

      it "returns the results" do
        expect(process).to match(
          [
            {
              record_identifier: "Teacher(##{teacher.id})",
              action: "update",
              changes: hash_including(
                "trn" => [teacher.trn.to_s, "123456"],
                "trs_first_name" => [teacher.trs_first_name, "New Name"]
              )
            },
            {
              record_identifier: "ECTAtSchoolPeriod(##{ect_at_school_period.id})",
              action: "delete",
              changes: {}
            }
          ]
        )
      end
    end
  end
end
