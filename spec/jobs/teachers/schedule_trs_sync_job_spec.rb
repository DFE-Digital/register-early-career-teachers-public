RSpec.describe Teachers::ScheduleTRSSyncJob, type: :job do
  describe "#perform" do
    let!(:teacher0) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: nil) }
    let!(:teacher1) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 5.days.ago) }
    let!(:teacher2) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 4.days.ago) }
    let!(:teacher3) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 3.days.ago) }
    let!(:teacher4) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 2.days.ago) }
    let!(:teacher5) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 1.day.ago) }

    it "schedules sync jobs for teachers ordered by trs_data_last_refreshed_at" do
      [
        [teacher0, 0],
        [teacher1, 3],
        [teacher2, 6],
        [teacher3, 9],
        [teacher4, 12],
        [teacher5, 15],
      ].each do |teacher, wait_time|
        allow(Teachers::SyncTeacherWithTRSJob).to receive(:set).with(wait: wait_time.seconds).and_return(Teachers::SyncTeacherWithTRSJob)

        expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher:)
      end

      described_class.perform_now
    end

    it "limits the number of teachers to BATCH_SIZE and picks them in order of last refreshed" do
      stub_const("Teachers::ScheduleTRSSyncJob::BATCH_SIZE", 3)

      # We expect the first 3 teachers to be processed (oldest refresh first)
      expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher: teacher0)
      expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher: teacher1)
      expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher: teacher2)

      # We don't expect the newer teachers to be processed
      expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher: teacher3)
      expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher: teacher4)
      expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher: teacher5)

      allow(Teachers::SyncTeacherWithTRSJob).to receive(:set).and_return(Teachers::SyncTeacherWithTRSJob)

      described_class.perform_now
    end

    it "uses the default queue" do
      expect(described_class.queue_name).to eq("default")
    end
  end
end
