require "rails_helper"

RSpec.describe Admin::UpdateInductionPeriod do
  subject(:service) { described_class.new(induction_period:, params:, author:) }

  let(:admin) { FactoryBot.create(:user, email: 'admin-user@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: admin.email) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:induction_period) do
    FactoryBot.create(
      :induction_period,
      teacher:,
      started_on: "2023-06-01",
      finished_on: "2023-12-31",
      number_of_terms: 2
    )
  end
  let(:params) { {} }

  describe "#update" do
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
        expect { service.update_induction! }.to change { induction_period.reload.started_on }.to(Date.parse("2024-01-01"))
          .and change { induction_period.reload.finished_on }.to(Date.parse("2024-12-31"))
          .and change { induction_period.reload.number_of_terms }.to(3)
          .and change { induction_period.reload.induction_programme }.to("cip")
      end
    end

    context "when induction period has an outcome" do
      let(:induction_period) { FactoryBot.create(:induction_period, teacher:, started_on: "2023-06-01", finished_on: "2023-12-31", outcome: "pass") }

      it "raises an error" do
        expect { service.update_induction! }.to raise_error(
          Admin::UpdateInductionPeriod::RecordedOutcomeError,
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
          expect { service.update_induction! }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Finished on The finish date must be later than the start date (31 December 2023)"
          )
        end
      end

      context "when start date is before QTS award date" do
        let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: Date.parse("2023-01-01")) }
        let(:params) { { started_on: "2022-12-31" } }

        it "raises an error" do
          expect { service.update_induction! }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Started on Start date cannot be before QTS award date (1 January 2023)"
          )
        end
      end

      context "with overlapping periods" do
        context "when overlapping with previous period" do
          let!(:previous_period) do
            FactoryBot.create(:induction_period,
                              teacher:,
                              started_on: "2023-01-01",
                              finished_on: "2023-07-01",
                              induction_programme: "cip")
          end

          let(:params) { { started_on: "2023-05-01" } }

          it "raises an error" do
            expect { service.update_induction! }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Started on Start date cannot overlap another induction period"
            )
          end
        end

        context "when overlapping with next period" do
          let!(:next_period) do
            FactoryBot.create(:induction_period,
                              teacher:,
                              started_on: "2023-11-01",
                              finished_on: "2024-05-01",
                              induction_programme: "cip")
          end

          let(:params) { { finished_on: "2023-12-01" } }

          it "raises an error" do
            expect { service.update_induction! }.to raise_error(
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
      end

      it "enqueues BeginECTInductionJob" do
        service.update_induction!

        expect(BeginECTInductionJob).to have_received(:perform_later).with(
          trn: teacher.trn,
          start_date: Date.parse("2023-01-01")
        )
      end

      context "when not the earliest period" do
        before do
          FactoryBot.create(:induction_period,
                            teacher:,
                            started_on: "2022-01-01",
                            finished_on: "2022-12-31",
                            induction_programme: "cip")
        end

        it "does not enqueue BeginECTInductionJob" do
          service.update_induction!

          expect(BeginECTInductionJob).not_to have_received(:perform_later)
        end
      end
    end
  end
end
