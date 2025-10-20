describe Teachers::RefreshTRSAttributes do
  include ActiveJob::TestHelper

  subject(:service) { Teachers::RefreshTRSAttributes.new(teacher) }

  let(:teacher) do
    FactoryBot.create(:teacher,
      trs_first_name: "Kermit",
      trs_last_name: "Van Bouten")
  end
  let(:enable_trs_teacher_refresh) { true }

  include_context "test trs api client that finds teacher that has passed their induction"

  before do
    allow(Rails.application.config).to receive(:enable_trs_teacher_refresh)
      .and_return(enable_trs_teacher_refresh)
  end

  describe "#refresh!" do
    it "updates the relevant TRS attributes" do
      freeze_time do
        expect(service.refresh!).to eq(:teacher_updated)

        teacher.reload
        # these values are returned by the fake API client
        expect(teacher.trs_first_name).to eql("Kirk")
        expect(teacher.trs_last_name).to eql("Van Houten")
        expect(teacher.trs_induction_status).to eql("Passed")
        expect(teacher.trs_qts_awarded_on).to eql(3.years.ago.to_date)
        expect(teacher.trs_qts_status_description).to eql("Passed")
        expect(teacher.trs_initial_teacher_training_provider_name).to eql("Example Provider Ltd.")
        expect(teacher.trs_initial_teacher_training_end_date).to eql(Date.new(2021, 4, 5))
        expect(teacher.trs_data_last_refreshed_at).to eql(Time.zone.now)
      end
    end

    it "adds a teacher_name_updated_by_trs event" do
      expect(teacher.events).to be_empty

      service.refresh!
      perform_enqueued_jobs

      expect(teacher.events.map(&:event_type)).to eql(%w[
        teacher_name_updated_by_trs
        teacher_trs_induction_status_updated
        teacher_trs_attributes_updated
      ])
    end

    describe "delegation" do
      before do
        allow(Teachers::Manage).to receive(:new).with(
          hash_including(
            teacher:,
            author: an_instance_of(Events::SystemAuthor),
            appropriate_body: nil
          )
        ).and_return(fake_manage)
      end

      context "when the teacher is found in TRS" do
        let(:fake_manage) do
          double(Teachers::Manage,
            update_name!: true,
            update_trs_attributes!: true,
            update_trs_induction_status!: true)
        end

        it "delegates to Teachers::Manage service" do
          freeze_time do
            service.refresh!

            expect(fake_manage).to have_received(:update_name!).once.with(
              trs_first_name: "Kirk",
              trs_last_name: "Van Houten"
            )
            expect(fake_manage).to have_received(:update_trs_attributes!).once.with({
              trs_data_last_refreshed_at: Time.zone.now,
              trs_initial_teacher_training_end_date: "2021-04-05",
              trs_initial_teacher_training_provider_name: "Example Provider Ltd.",
              trs_qts_awarded_on: 3.years.ago.to_date,
              trs_qts_status_description: "Passed"
            })
            expect(fake_manage).to have_received(:update_trs_induction_status!).once.with(
              trs_induction_status: "Passed",
              trs_induction_start_date: "2021-01-01",
              trs_induction_completed_date: "2022-01-01"
            )
          end
        end
      end

      context "when the teacher has been deactivated in TRS" do
        include_context "test trs api client deactivated teacher"

        let(:fake_manage) do
          double(Teachers::Manage,
            mark_teacher_as_deactivated!: true)
        end

        it "marks the teacher as deactivated when the TRS reports the teacher as 'gone'" do
          freeze_time do
            expect(service.refresh!).to eq(:teacher_deactivated)
            expect(fake_manage).to have_received(:mark_teacher_as_deactivated!).once.with(
              trs_data_last_refreshed_at: Time.zone.now
            )
          end
        end
      end
    end

    context "when enable_trs_teacher_refresh is false" do
      let(:enable_trs_teacher_refresh) { false }

      it "does not refresh the teacher's TRS attributes" do
        expect(service).not_to be_enabled
        expect(service.refresh!).to eq(:refresh_disabled)
        expect { service.refresh! }.not_to(change { teacher.reload.attributes })
      end
    end
  end
end
