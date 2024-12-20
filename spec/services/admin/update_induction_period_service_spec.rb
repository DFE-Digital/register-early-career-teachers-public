require "rails_helper"

RSpec.describe Admin::UpdateInductionPeriodService do
  subject(:service) { described_class.new(induction_period: induction_period, params: params) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:induction_period) { FactoryBot.create(:induction_period, teacher: teacher, started_on: "2023-06-01", finished_on: "2023-12-31") }
  let(:params) { {} }

  describe "#call" do
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
        expect { service.call }.to change { induction_period.reload.started_on }.to(Date.parse("2024-01-01"))
          .and change { induction_period.reload.finished_on }.to(Date.parse("2024-12-31"))
          .and change { induction_period.reload.number_of_terms }.to(3)
          .and change { induction_period.reload.induction_programme }.to("cip")
      end
    end

    context "when induction period has an outcome" do
      before do
        induction_period.update!(outcome: "pass")
      end

      it "raises an error" do
        expect { service.call }.to raise_error(
          Admin::UpdateInductionPeriodService::RecordedOutcomeError,
          "Cannot edit induction period with recorded outcome"
        )
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
          expect { service.call }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Finished on must be later than the start date, Started on must be before end date"
          )
        end
      end

      context "when start date is before QTS award date" do
        let(:teacher) { FactoryBot.create(:teacher, qts_awarded_on: Date.parse("2023-01-01")) }
        let(:params) { { started_on: "2022-12-31" } }

        it "raises an error" do
          expect { service.call }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Started on cannot be before QTS award date"
          )
        end
      end

      context "with overlapping periods" do
        context "when overlapping with previous period" do
          let!(:previous_period) do
            FactoryBot.create(:induction_period,
                              teacher: teacher,
                              started_on: "2023-01-01",
                              finished_on: "2023-07-01",
                              induction_programme: "cip")
          end

          let(:params) { { started_on: "2023-05-01" } }

          it "raises an error" do
            expect { service.call }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Induction periods cannot overlap"
            )
          end
        end

        context "when overlapping with next period" do
          let!(:next_period) do
            FactoryBot.create(:induction_period,
                              teacher: teacher,
                              started_on: "2023-11-01",
                              finished_on: "2024-05-01",
                              induction_programme: "cip")
          end

          let(:params) { { finished_on: "2023-12-01" } }

          it "raises an error" do
            expect { service.call }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Induction periods cannot overlap"
            )
          end
        end
      end
    end

    context "when updating earliest period start date" do
      let(:params) { { started_on: "2023-01-01" } }

      before do
        allow(BeginECTInductionJob).to receive(:perform_later)
      end

      it "enqueues BeginECTInductionJob" do
        service.call

        expect(BeginECTInductionJob).to have_received(:perform_later).with(
          trn: teacher.trn,
          start_date: Date.parse("2023-01-01"),
          teacher_id: teacher.id
        )
      end

      context "when not the earliest period" do
        before do
          FactoryBot.create(:induction_period,
                            teacher: teacher,
                            started_on: "2022-01-01",
                            finished_on: "2022-12-31",
                            induction_programme: "cip")
        end

        it "does not enqueue BeginECTInductionJob" do
          service.call

          expect(BeginECTInductionJob).not_to have_received(:perform_later)
        end
      end
    end
  end
end
