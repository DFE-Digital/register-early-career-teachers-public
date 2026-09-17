RSpec.describe Admin::DataFixes::Changes do
  subject(:changes) { described_class.new(parsed_rows:) }

  before { freeze_time }

  let!(:teacher) { FactoryBot.create(:teacher) }
  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }

  describe "#process" do
    subject(:process) { changes.process }

    context "when none of the changes are valid" do
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

      it "returns the saved changes" do
        expect(process).to eq(
          [
            {
              gid: teacher.to_global_id.to_s,
              action: "update",
              changes: {
                "trn" => [teacher.trn.to_s, "123456"],
                "trs_first_name" => [teacher.trs_first_name, "New Name"]
              }
            },
            {
              gid: ect_at_school_period.to_global_id.to_s,
              action: "delete",
              changes: {}
            }
          ]
        )
      end
    end
  end

  describe "#results" do
    subject(:results) { changes.results }

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

    it "maps parsed rows to their processed results" do
      expect(results.first).to have_attributes(
        target_object: teacher,
        action: "update",
        success?: true,
        error: nil,
        saved_change: {
          gid: teacher.to_global_id.to_s,
          action: "update",
          changes: {
            "trn" => [teacher.trn.to_s, "123456"],
            "trs_first_name" => [teacher.trs_first_name, "New Name"]
          }
        }
      )
      expect(results.second).to have_attributes(
        target_object: nil,
        action: "destroy",
        success?: false,
        error: instance_of(ArgumentError),
        saved_change: nil
      )
    end
  end
end
