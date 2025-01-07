require "rails_helper"

RSpec.describe Admin::InductionPeriodsController do
  include ActionView::Helpers::SanitizeHelper

  include_context 'fake session manager for DfE user'

  describe "GET /admin/induction_periods/:id/edit" do
    let(:induction_period) { FactoryBot.create(:induction_period, started_on: 1.year.ago, finished_on: 6.months.ago) }

    it "returns success" do
      get edit_admin_teacher_induction_period_path(induction_period.teacher, induction_period)
      expect(response).to be_successful
    end
  end

  describe "PATCH /admin/induction_periods/:id" do
    context "when induction period has no outcome" do
      let!(:induction_period) { FactoryBot.create(:induction_period, started_on: 1.year.ago, finished_on: 6.months.ago) }

      context "with valid params" do
        let(:valid_params) do
          {
            induction_period: {
              started_on: 1.month.ago.to_date,
              finished_on: Date.current,
              number_of_terms: 1,
              induction_programme: "cip"
            }
          }
        end

        it "updates the induction period" do
          patch admin_teacher_induction_period_path(induction_period.teacher, induction_period), params: valid_params

          expect(response).to redirect_to(admin_teacher_path(induction_period.teacher))
          expect(flash[:notice]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.started_on).to eq(valid_params[:induction_period][:started_on])
          expect(induction_period.finished_on).to eq(valid_params[:induction_period][:finished_on])
          expect(induction_period.number_of_terms).to eq(valid_params[:induction_period][:number_of_terms])
          expect(induction_period.induction_programme).to eq(valid_params[:induction_period][:induction_programme])
        end

        context "when updating earliest period start date" do
          let!(:teacher) { FactoryBot.create(:teacher) }
          let!(:earliest_period) { FactoryBot.create(:induction_period, teacher: teacher, started_on: 2.years.ago, finished_on: 18.months.ago) }
          let!(:later_period) { FactoryBot.create(:induction_period, teacher: teacher, started_on: 1.year.ago, finished_on: 6.months.ago) }

          it "enqueues BeginECTInductionJob" do
            expect {
              patch admin_teacher_induction_period_path(earliest_period.teacher, earliest_period), params: {
                induction_period: { started_on: 20.months.ago }
              }
            }.to have_enqueued_job(BeginECTInductionJob)
              .with(
                trn: teacher.trn,
                start_date: 20.months.ago.to_date,
                teacher_id: teacher.id
              )
          end
        end
      end

      context "with invalid params" do
        context "when start date is after end date" do
          let(:invalid_params) do
            {
              induction_period: {
                started_on: Date.current,
                finished_on: 1.month.ago
              }
            }
          end

          it "returns error" do
            patch admin_teacher_induction_period_path(induction_period.teacher, induction_period), params: invalid_params
            expect(response).to be_unprocessable
            expect(response.body).to include("The finish date must be later than the start date")
          end
        end

        context "when dates would cause overlap" do
          let!(:teacher) { FactoryBot.create(:teacher) }
          let!(:first_period) { FactoryBot.create(:induction_period, teacher: teacher, started_on: 1.year.ago, finished_on: 6.months.ago) }
          let!(:second_period) { FactoryBot.create(:induction_period, teacher: teacher, started_on: 5.months.ago, finished_on: 1.month.ago) }

          it "returns error" do
            patch admin_teacher_induction_period_path(second_period.teacher, second_period), params: {
              induction_period: { started_on: 7.months.ago }
            }
            expect(response).to be_unprocessable
            expect(sanitize(response.body)).to include("Induction periods cannot overlap")
          end
        end

        context "when start date is before QTS date" do
          let(:teacher) { FactoryBot.create(:teacher, qts_awarded_on: 1.year.ago) }
          let(:induction_period) { FactoryBot.create(:induction_period, started_on: 6.months.ago, finished_on: 1.month.ago, teacher: teacher) }

          it "returns error" do
            patch admin_teacher_induction_period_path(induction_period.teacher, induction_period), params: {
              induction_period: { started_on: 2.years.ago }
            }
            expect(response).to be_unprocessable
            expect(response.body).to include("Started on cannot be before QTS award date")
          end
        end
      end
    end
  end
end
