RSpec.describe Teachers::MergeTRN::TRSSyncJob do
  describe "#perform" do
    subject(:perform) do
      described_class.perform_now(teacher:, teacher_started_induction_on:)
    end

    let(:teacher) { FactoryBot.create(:teacher) }

    let(:api_client) { instance_double(TRS::APIClient, begin_induction!: true) }

    before { allow(TRS::APIClient).to receive(:build).and_return(api_client) }

    context "when there is a `teacher_started_induction_on` date" do
      let(:teacher_started_induction_on) { Date.yesterday }

      it "begins induction with TRS" do
        perform
        expect(api_client)
          .to have_received(:begin_induction!)
          .with(trn: teacher.trn, start_date: teacher_started_induction_on)
      end

      it "enqueues a `Teachers::SyncTeacherWithTRSJob` job" do
        freeze_time

        expect { perform }
          .to have_enqueued_job(Teachers::SyncTeacherWithTRSJob)
          .at(5.minutes.from_now)
          .with(teacher:)
      end
    end

    context "When there is no `teacher_started_induction_on` date" do
      let(:teacher_started_induction_on) { nil }

      it "does not begin induction with TRS" do
        perform
        expect(api_client).not_to have_received(:begin_induction!)
      end

      it "enqueues a `Teachers::SyncTeacherWithTRSJob` job" do
        freeze_time

        expect { perform }
          .to have_enqueued_job(Teachers::SyncTeacherWithTRSJob)
          .at(5.minutes.from_now)
          .with(teacher:)
      end
    end
  end
end
