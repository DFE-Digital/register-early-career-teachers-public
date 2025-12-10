RSpec.describe Teachers::ImportEarlyRolloutMentor do
  include ActiveJob::TestHelper

  subject(:service) { described_class.new(trn:) }

  let(:trn) { "1234567" }

  before { clear_enqueued_jobs }

  after { clear_enqueued_jobs }

  describe "#call" do
    it "creates the teacher flagged as an Early Roll-out mentor" do
      expect { service.call }.to change(Teacher, :count).by(1)

      teacher = Teacher.find_by(trn:)
      expect(teacher.mentor_became_ineligible_for_funding_on).to eq(Date.new(2021, 4, 19))
      expect(teacher.mentor_became_ineligible_for_funding_reason).to eq("completed_during_early_roll_out")
    end

    it "records an import_from_dqt event" do
      expect { service.call }
        .to have_enqueued_job(RecordEventJob)
        .with(
          hash_including(
            event_type: :import_from_dqt,
            body: "Teacher created with Early Roll-out mentor attributes during the import"
          )
        )
        .exactly(:once)
    end

    it "queues a TRS attribute refresh" do
      expect { service.call }
        .to have_enqueued_job(Teachers::SyncTeacherWithTRSJob)
        .exactly(:once)
    end

    context "when the teacher already exists" do
      let!(:existing_teacher) { FactoryBot.create(:teacher, trn:) }

      it "updates the existing teacher with the Early Roll-out mentor flags" do
        expect { service.call }.not_to change(Teacher, :count)

        existing_teacher.reload
        expect(existing_teacher.mentor_became_ineligible_for_funding_on).to eq(Date.new(2021, 4, 19))
        expect(existing_teacher.mentor_became_ineligible_for_funding_reason).to eq("completed_during_early_roll_out")
      end

      it "records an import_from_dqt event" do
        expect { service.call }
          .to have_enqueued_job(RecordEventJob)
          .with(
            hash_including(
              event_type: :import_from_dqt,
              body: "Teacher updated with Early Roll-out mentor attributes during the import"
            )
          )
          .exactly(:once)
      end

      it "queues a TRS attribute refresh" do
        expect { service.call }
          .to have_enqueued_job(Teachers::SyncTeacherWithTRSJob)
          .exactly(:once)
      end
    end

    context "with an invalid TRN" do
      let(:trn) { "INVALID" }

      it "raises an argument error" do
        expect { service.call }.to raise_error(ArgumentError, "TRN must be 7 digits")
      end
    end
  end
end
