describe TeacherHistoryConverter::Cleaner::ProviderLedECTWithoutPartnership do
  subject(:cleaner) { described_class.new(raw_induction_records, participant_type) }

  describe "#induction_records" do
    let(:participant_type) { :ect }

    let(:school_1) { Types::SchoolData.new(urn: 123_456, name: "School A") }
    let(:school_2) { Types::SchoolData.new(urn: 456_789, name: "School B") }
    let(:training_programme_1) { "full_induction_programme" }
    let(:training_programme_2) { "core_induction_programme" }

    let(:induction_record_1) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2021, 9, 1),
        end_date: Date.new(2022, 3, 15),
        created_at: Time.zone.local(2020, 9, 1, 12, 0, 0),
        school: school_1,
        training_programme: training_programme_1,
        training_provider_info: nil
      )
    end
    let(:induction_record_2) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 6, 1),
        end_date: Date.new(2022, 8, 31),
        created_at: Time.zone.local(2021, 9, 1, 12, 0, 0),
        school: school_1,
        training_programme: training_programme_1
      )
    end
    let(:induction_record_3) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 9, 1),
        end_date: Date.new(2023, 8, 31),
        created_at: Time.zone.local(2021, 9, 1, 12, 0, 0),
        school: school_2,
        training_programme: training_programme_2
      )
    end
    let(:raw_induction_records) { [induction_record_1, induction_record_2, induction_record_3] }

    it "removes provider_led induction records without a provider" do
      expect(cleaner.induction_records).to contain_exactly(induction_record_2, induction_record_3)
    end

    context "when the participant_type is a Mentor" do
      let(:participant_type) { :mentor }

      it "does not remove any records" do
        expect(cleaner.induction_records).to match_array raw_induction_records
      end
    end
  end
end
