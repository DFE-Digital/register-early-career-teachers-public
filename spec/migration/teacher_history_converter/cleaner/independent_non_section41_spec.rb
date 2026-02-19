describe TeacherHistoryConverter::Cleaner::IndependentNonSection41 do
  subject(:cleaner) { described_class.new(raw_induction_records) }

  describe "#induction_records" do
    let(:school_1) { Types::SchoolData.new(urn: 123_456, name: "School A", school_type_name: "Other independent special school") }
    let(:school_2) { Types::SchoolData.new(urn: 456_789, name: "School B", school_type_name: "Academy converter") }

    let(:training_programme_1) { "core_induction_programme" }
    let(:training_programme_2) { "core_induction_programme" }

    let(:section41_reader) { instance_double(Section41Reader) }
    let(:section41_data) { [] }

    let(:first_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2021, 9, 1),
        end_date: Date.new(2022, 3, 15),
        created_at: Time.zone.local(2020, 9, 1, 12, 0, 0),
        school: school_1,
        training_programme: training_programme_1
      )
    end
    let(:second_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 6, 1),
        end_date: Date.new(2022, 8, 31),
        created_at: Time.zone.local(2021, 9, 1, 12, 0, 0),
        school: school_1,
        training_programme: training_programme_2
      )
    end
    let(:third_induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 9, 1),
        end_date: Date.new(2023, 8, 31),
        created_at: Time.zone.local(2021, 9, 1, 12, 0, 0),
        school: school_2
      )
    end
    let(:raw_induction_records) { [first_induction_record, second_induction_record, third_induction_record] }

    before do
      allow(Section41Reader).to receive(:new).and_return(section41_reader)
      allow(section41_reader).to receive(:section41_approvals).and_return(section41_data)
    end

    context "when the school is not an independent type" do
      let(:school_1) { Types::SchoolData.new(urn: 123_456, name: "School A", school_type_name: "Community school") }

      it "returns all the induction records for the school" do
        expect(cleaner.induction_records).to match_array raw_induction_records
      end
    end

    context "when the school is an independent type" do
      context "when the school does not have section 41" do
        context "when there is one or more provider-led induction records at the school" do
          let(:training_programme_1) { "full_induction_programme" }

          it "returns all induction records for the school" do
            expect(cleaner.induction_records).to match_array raw_induction_records
          end
        end

        context "when there are no provider-led induction records at the school" do
          it "does not return any induction records for the school" do
            expect(cleaner.induction_records).to eq [third_induction_record]
          end
        end
      end

      context "the first induction record started after the school had section 41" do
        let(:section41_data) { [{ "urn" => school_1.urn, "s41_granted" => "01/01/2020", "s41_revoked" => nil }] }

        it "returns all the induction records for the school" do
          expect(cleaner.induction_records).to match_array raw_induction_records
        end
      end

      context "the first induction record started before the school had section 41" do
        let(:section41_data) { [{ "urn" => school_1.urn, "s41_granted" => "01/01/2022", "s41_revoked" => nil }] }

        it "does not return any induction records for the school" do
          expect(cleaner.induction_records).to eq [third_induction_record]
        end
      end

      context "the first induction record started after the school had section 41 revoked" do
        let(:section41_data) { [{ "urn" => school_1.urn, "s41_granted" => nil, "s41_revoked" => "01/01/2021" }] }

        it "does not return any induction records for the school" do
          expect(cleaner.induction_records).to eq [third_induction_record]
        end
      end

      context "the first induction record started before the school had section 41 revoked" do
        let(:section41_data) { [{ "urn" => school_1.urn, "s41_granted" => nil, "s41_revoked" => "01/01/2022" }] }

        it "returns all the induction records for the school" do
          expect(cleaner.induction_records).to match_array raw_induction_records
        end
      end
    end
  end
end
