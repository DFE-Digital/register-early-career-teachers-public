describe TeacherHistoryConverter::Cleaner do
  let(:induction_records) { FactoryBot.build_list(:ecf1_teacher_history_induction_record_row, 5) }
  let(:participant_type) { :ect }
  let(:migration_mode) { "latest_induction_records" }

  let(:cleaner_steps) do
    [
      TeacherHistoryConverter::Cleaner::BritishSchoolsOverseas,
      TeacherHistoryConverter::Cleaner::SchoolFundedFip,
      TeacherHistoryConverter::Cleaner::IndependentNonSection41,
      TeacherHistoryConverter::Cleaner::ServiceStartDate,
      TeacherHistoryConverter::Cleaner::CorruptedDates,
      TeacherHistoryConverter::Cleaner::ZeroDay,
      TeacherHistoryConverter::Cleaner::OverrideFirstStartDateWithCreationDateIfEarlier,
      TeacherHistoryConverter::Cleaner::OverrideFirstStartDateForInductionRecordIntroduction,
      TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate
    ]
  end

  context "when the migration_mode is 'latest_induction_records'" do
    it "calls all of the cleaner steps once" do
      cleaner_steps.each { |cleaner| allow(cleaner).to receive(:new).and_call_original }
      TeacherHistoryConverter::Cleaner.new(induction_records, participant_type:, migration_mode:).induction_records
      expect(cleaner_steps).to all(have_received(:new).once)
    end

    context "when an induction_completion_date is present" do
      let(:induction_completion_date) { Date.new(2026, 1, 2) }

      it "is passed into the 'snip ongoing records to induction completion date' object" do
        allow(TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate).to receive(:new).and_call_original
        TeacherHistoryConverter::Cleaner.new(induction_records, participant_type:, induction_completion_date:).induction_records
        expect(TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate).to have_received(:new).with(induction_records, induction_completion_date:)
      end
    end

    context "when we need to know the participant_type in the cleaner" do
      it "is passed into the 'remove provider_led ECT without partnerships' cleaner" do
        allow(TeacherHistoryConverter::Cleaner::ProviderLedECTWithoutPartnership).to receive(:new).and_call_original
        TeacherHistoryConverter::Cleaner.new(induction_records, participant_type:).induction_records
        expect(TeacherHistoryConverter::Cleaner::ProviderLedECTWithoutPartnership).to have_received(:new).with(induction_records, participant_type)
      end
    end
  end

  context "when the migration_mode is 'all_induction_records'" do
    let(:migration_mode) { "all_induction_records" }
    let(:premium_cleaner_steps) do
      [
        TeacherHistoryConverter::Cleaner::BritishSchoolsOverseas,
        TeacherHistoryConverter::Cleaner::SchoolFundedFip,
        TeacherHistoryConverter::Cleaner::IndependentNonSection41,
      ]
    end

    it "calls all of the premium cleaner steps once" do
      premium_cleaner_steps.each { |cleaner| allow(cleaner).to receive(:new).and_call_original }
      TeacherHistoryConverter::Cleaner.new(induction_records, participant_type:, migration_mode:).induction_records
      expect(premium_cleaner_steps).to all(have_received(:new).once)
    end

    it "does not call the economy mode cleaner steps" do
      economy_steps = cleaner_steps - premium_cleaner_steps

      economy_steps.each { |cleaner| allow(cleaner).to receive(:new).and_call_original }
      TeacherHistoryConverter::Cleaner.new(induction_records, participant_type:, migration_mode:).induction_records
      economy_steps.each { |cleaner| expect(cleaner).not_to have_received(:new) }
    end
  end
end
