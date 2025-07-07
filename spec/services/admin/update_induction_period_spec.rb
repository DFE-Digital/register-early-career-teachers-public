RSpec.describe Admin::UpdateInductionPeriod do
  subject(:service) { described_class.new(author:, induction_period:, params:) }

  let(:admin) { create(:user, email: 'admin-user@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: admin.email) }
  let(:teacher) { create(:teacher) }
  let(:appropriate_body) { create(:appropriate_body) }
  let(:induction_period) do
    create(
      :induction_period,
      teacher:,
      appropriate_body:,
      started_on: "2023-06-01",
      finished_on: "2023-12-31"
    )
  end
  let(:params) { {} }

  describe "#update_induction_period!" do
    context "with valid params" do
      let(:params) do
        {
          started_on: "2024-01-01",
          finished_on: "2024-12-31",
          number_of_terms: 3,
          induction_programme: "cip"
        }
      end

      it "updates the induction period" do
        expect { service.update_induction_period! }.to change { induction_period.reload.started_on }.to(Date.parse("2024-01-01"))
          .and change { induction_period.reload.finished_on }.to(Date.parse("2024-12-31"))
          .and change { induction_period.reload.number_of_terms }.to(3)
          .and change { induction_period.reload.induction_programme }.to("cip")
      end
    end

    context "when induction period has an outcome" do
      let(:induction_period) do
        create(:induction_period,
               teacher:,
               appropriate_body:,
               started_on: "2023-01-01",
               finished_on: "2023-12-31",
               outcome: "pass",
               number_of_terms: 3)
      end

      context "when updating dates" do
        let(:params) { { started_on: "2023-02-01", finished_on: "2024-01-31" } }

        before do
          allow(PassECTInductionJob).to receive(:perform_later)
        end

        it "allows updating dates" do
          service.update_induction_period!

          expect(induction_period.reload.started_on).to eq(Date.parse("2023-02-01"))
          expect(induction_period.reload.finished_on).to eq(Date.parse("2024-01-31"))
        end

        it "notifies TRS of the updated dates" do
          service.update_induction_period!

          expect(PassECTInductionJob).to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: Date.parse("2023-02-01"),
            completed_date: Date.parse("2024-01-31"),
            pending_induction_submission_id: nil
          )
        end

        context "when trying to set end date to nil" do
          let(:params) { { finished_on: nil } }

          it "raises an error" do
            expect { service.update_induction_period! }.to raise_error(
              ActiveRecord::RecordInvalid,
              "End date cannot be set to nil for induction periods with outcomes"
            )
          end
        end

        context "when updating other fields with nil dates" do
          let(:params) { { number_of_terms: 3.5, started_on: nil } }

          it "raises an error" do
            expect { service.update_induction_period! }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Started on Enter a start date"
            )
          end
        end
      end

      context "when updating number of terms" do
        let(:params) { { number_of_terms: 3.5 } }

        it "allows updating number of terms" do
          service.update_induction_period!

          expect(induction_period.reload.number_of_terms).to eq(3.5)
        end
      end

      context "when updating induction programme" do
        let(:params) { { induction_programme: "cip" } }

        it "allows updating induction programme" do
          service.update_induction_period!

          expect(induction_period.reload.induction_programme).to eq("cip")
        end
      end
    end

    context "when induction period has a fail outcome" do
      let(:induction_period) do
        create(:induction_period,
               teacher:,
               appropriate_body:,
               started_on: "2023-01-01",
               finished_on: "2023-12-31",
               outcome: "fail",
               number_of_terms: 3)
      end

      context "when updating end date" do
        let(:params) { { finished_on: "2024-01-31" } }

        before do
          allow(FailECTInductionJob).to receive(:perform_later)
        end

        it "notifies TRS of the updated end date" do
          service.update_induction_period!

          expect(FailECTInductionJob).to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: Date.parse("2023-01-01"),
            completed_date: Date.parse("2024-01-31"),
            pending_induction_submission_id: nil
          )
        end
      end
    end

    context "with invalid dates" do
      context "when start date is after end date" do
        let(:params) do
          {
            started_on: "2023-12-31",
            finished_on: "2023-01-01"
          }
        end

        it "raises an error" do
          expect { service.update_induction_period! }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Finished on The end date must be later than the start date (31 December 2023)"
          )
        end
      end

      context "when start date is before QTS award date" do
        let(:teacher) { create(:teacher, trs_qts_awarded_on: Date.parse("2023-01-01")) }
        let(:params) { { started_on: "2022-12-31" } }

        it "raises an error" do
          expect { service.update_induction_period! }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Started on Start date cannot be before QTS award date (1 January 2023)"
          )
        end
      end

      context "with overlapping periods" do
        context "when overlapping with previous period" do
          let!(:previous_period) do
            create(:induction_period,
                   teacher:,
                   started_on: "2023-01-01",
                   finished_on: "2023-07-01",
                   induction_programme: "cip")
          end

          let(:params) { { started_on: "2023-05-01" } }

          it "raises an error" do
            expect { service.update_induction_period! }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Started on Start date cannot overlap another induction period"
            )
          end
        end

        context "when overlapping with next period" do
          let!(:next_period) do
            create(:induction_period,
                   teacher:,
                   started_on: "2023-11-01",
                   finished_on: "2024-05-01",
                   induction_programme: "cip")
          end

          let(:params) { { finished_on: "2023-12-01" } }

          it "raises an error" do
            expect { service.update_induction_period! }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Finished on End date cannot overlap another induction period"
            )
          end
        end
      end
    end

    context "when updating earliest period start date" do
      let(:params) { { started_on: "2023-01-01" } }

      before do
        allow(BeginECTInductionJob).to receive(:perform_later)
        allow(Events::Record).to receive(:record_teacher_trs_induction_start_date_updated_event!)
      end

      context "when induction period has no outcome and no end date" do
        let(:induction_period) do
          create(
            :induction_period,
            teacher:,
            appropriate_body:,
            started_on: "2023-06-01",
            finished_on: nil,
            outcome: nil,
            number_of_terms: nil
          )
        end

        it "enqueues BeginECTInductionJob and records start date event" do
          service.update_induction_period!

          expect(BeginECTInductionJob).to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: Date.parse("2023-01-01")
          )

          expect(Events::Record).to have_received(:record_teacher_trs_induction_start_date_updated_event!).with(
            author:,
            teacher:,
            appropriate_body:,
            induction_period:
          )
        end
      end

      context "when induction period has an outcome" do
        let(:induction_period) do
          create(
            :induction_period,
            teacher:,
            appropriate_body:,
            started_on: "2023-06-01",
            finished_on: "2023-12-31",
            outcome: "pass"
          )
        end

        let(:params) do
          {
            started_on: "2023-01-01",
            finished_on: "2024-01-31"
          }
        end

        before do
          allow(PassECTInductionJob).to receive(:perform_later)
          allow(Events::Record).to receive(:record_teacher_trs_induction_start_date_updated_event!)
          allow(Events::Record).to receive(:record_teacher_trs_induction_end_date_updated_event!)
        end

        it "sends pass notification and records both events" do
          service.update_induction_period!

          expect(PassECTInductionJob).to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: Date.parse("2023-01-01"),
            completed_date: Date.parse("2024-01-31"),
            pending_induction_submission_id: nil
          )

          expect(Events::Record).to have_received(:record_teacher_trs_induction_start_date_updated_event!).with(
            author:,
            teacher:,
            appropriate_body:,
            induction_period:
          )

          expect(Events::Record).to have_received(:record_teacher_trs_induction_end_date_updated_event!).with(
            author:,
            teacher:,
            appropriate_body:,
            induction_period:
          )
        end
      end
    end

    context "when updating end date for induction with outcome" do
      let(:induction_period) do
        create(
          :induction_period,
          teacher:,
          appropriate_body:,
          started_on: "2023-01-01",
          finished_on: "2023-12-31",
          outcome: "pass"
        )
      end

      let(:params) { { finished_on: "2024-01-31" } }

      before do
        allow(PassECTInductionJob).to receive(:perform_later)
        allow(Events::Record).to receive(:record_teacher_trs_induction_end_date_updated_event!)
      end

      it "sends pass notification and records end date event" do
        service.update_induction_period!

        expect(PassECTInductionJob).to have_received(:perform_later).with(
          trn: teacher.trn,
          start_date: Date.parse("2023-01-01"),
          completed_date: Date.parse("2024-01-31"),
          pending_induction_submission_id: nil
        )

        expect(Events::Record).to have_received(:record_teacher_trs_induction_end_date_updated_event!).with(
          author:,
          teacher:,
          appropriate_body:,
          induction_period:
        )
      end
    end
  end
end
