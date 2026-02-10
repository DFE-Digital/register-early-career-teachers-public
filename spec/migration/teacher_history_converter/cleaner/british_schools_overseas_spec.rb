describe TeacherHistoryConverter::Cleaner::BritishSchoolsOverseas do
  subject(:cleaner) { described_class.new(raw_induction_records) }

  describe "#induction_records" do
    let(:school_1) { Types::SchoolData.new(urn: 123_456, name: "School A", school_type_name: "Community school") }
    let(:school_2) { Types::SchoolData.new(urn: 456_789, name: "School B", school_type_name: "Academy converter") }

    let(:first_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2020, 9, 1),
        end_date: Date.new(2021, 3, 15),
        created_at: Time.zone.local(2020, 9, 1, 12, 0, 0),
        school: school_1
      )
    end
    let(:second_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2021, 9, 1),
        end_date: Date.new(2022, 8, 31),
        created_at: Time.zone.local(2021, 9, 1, 12, 0, 0),
        school: school_2
      )
    end
    let(:raw_induction_records) { [first_induction_record, second_induction_record] }

    it "returns the induction records" do
      expect(cleaner.induction_records).to match_array(raw_induction_records)
    end

    context "when an induction record is associated with a school of the GIAS establishment type British Schools Overseas" do
      let(:school_1) { Types::SchoolData.new(urn: 123_456, name: "School A", school_type_name: "British schools overseas") }

      it "does not return that induction record" do
        expect(cleaner.induction_records).to eq [second_induction_record]
      end
    end
  end
end
