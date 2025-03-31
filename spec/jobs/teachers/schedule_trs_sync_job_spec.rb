require "rails_helper"

RSpec.describe Teachers::ScheduleTRSSyncJob, type: :job do
  describe "#perform" do
    let!(:teacher1) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 5.days.ago) }
    let!(:teacher2) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 4.days.ago) }
    let!(:teacher3) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 3.days.ago) }
    let!(:teacher4) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 2.days.ago) }
    let!(:teacher5) { FactoryBot.create(:teacher, trs_data_last_refreshed_at: 1.day.ago) }

    it "schedules sync jobs for teachers ordered by trs_data_last_refreshed_at" do
      ordered_teachers = Teacher.order(trs_data_last_refreshed_at: :asc).limit(described_class::BATCH_SIZE)

      ordered_teachers.each_with_index do |teacher, i|
        allow(Teachers::SyncTeacherWithTRSJob).to receive(:set)
          .with(wait: (i * 3).seconds)
          .and_return(Teachers::SyncTeacherWithTRSJob)

        expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later)
          .with(teacher:)
      end

      described_class.perform_now
    end

    it "limits the number of teachers to BATCH_SIZE and picks them in order of last refreshed" do
      stub_const("Teachers::ScheduleTRSSyncJob::BATCH_SIZE", 3)

      # We expect the first 3 teachers to be processed (oldest refresh first)
      expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher: teacher1)
      expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher: teacher2)
      expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher: teacher3)

      # We don't expect the newer teachers to be processed
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
