RSpec.describe 'Appropriate body editing an active induction period', type: :request do
  include_context 'sign in as non-DfE user'

  let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe "GET /appropriate-body/teachers/:teacher_id/induction-periods/:id/edit" do
    let(:induction_period) do
      FactoryBot.create(:induction_period, teacher:, started_on: 9.months.ago, finished_on: 6.months.ago)
    end

    it "returns success" do
      get edit_ab_teacher_induction_period_path(induction_period.teacher, induction_period)
      expect(response).to be_successful
    end
  end

  describe "PATCH /appropriate-body/teachers/:teacher_id/induction-periods/:id" do
    let(:params) do
      {
        induction_period: {
          started_on:,
          finished_on:,
          number_of_terms:,
          induction_programme:,
          appropriate_body_id: appropriate_body.id
        }
      }
    end

    let(:number_of_terms) { 1 }
    let(:induction_programme) { "cip" }

    context "when induction period has no outcome" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, teacher:, started_on: 9.months.ago, finished_on: 6.months.ago)
      end

      context "with valid params" do
        let(:started_on) { 5.months.ago.to_date }
        let(:finished_on) { 3.months.ago.to_date }

        it "updates the induction period" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).to redirect_to(ab_teacher_path(induction_period.teacher))
          expect(flash[:alert]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.started_on).to eq(started_on)
          expect(induction_period.finished_on).to eq(finished_on)
          expect(induction_period.number_of_terms).to eq(number_of_terms)
          expect(induction_period.induction_programme).to eq(induction_programme)

          expect(induction_period.training_programme).to eq('provider_led')
          expect(induction_period.appropriate_body).to eq(appropriate_body)
        end

        it "records an induction period updated event" do
          allow(Events::Record).to receive(:record_induction_period_updated_event!).once.and_call_original

          induction_period.assign_attributes(params[:induction_period])

          expected_modifications = induction_period.changes

          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(Events::Record).to have_received(:record_induction_period_updated_event!).once.with(
            hash_including(
              {
                induction_period:,
                teacher: induction_period.teacher,
                appropriate_body: induction_period.appropriate_body,
                modifications: expected_modifications,
                author: kind_of(Sessions::User),
              }
            )
          )
        end

        context "when dates would cause overlap" do
          before do
            FactoryBot.create(:induction_period, teacher:, started_on: 1.year.ago, finished_on: 8.months.ago)
          end

          let(:induction_period) do
            FactoryBot.create(:induction_period, teacher:, started_on: 6.months.ago, finished_on: 3.months.ago)
          end

          let(:started_on) { 9.months.ago.to_date }

          it "returns error" do
            patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

            expect(response).not_to redirect_to(ab_teacher_path(induction_period.teacher))
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include("Start date cannot overlap another induction period")
          end
        end

        context "when updating earliest period start date" do
          before do
            teacher.induction_periods.destroy_all
            allow(BeginECTInductionJob).to receive(:perform_later)
          end

          let!(:earliest_period) do
            FactoryBot.create(:induction_period,
                              teacher:,
                              started_on: 12.months.ago,
                              finished_on: nil,
                              number_of_terms: nil)
          end

          let(:params) do
            { induction_period: { started_on: 11.months.ago } }
          end

          it "enqueues BeginECTInductionJob" do
            patch(ab_teacher_induction_period_path(teacher, earliest_period), params:)
            expect(BeginECTInductionJob).to have_received(:perform_later).with(
              trn: teacher.trn,
              start_date: params[:induction_period][:started_on].to_date
            )
          end
        end
      end

      context "with invalid params" do
        before do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)
        end

        context "when start date is after end date" do
          let(:started_on) { 3.months.ago.to_date }
          let(:finished_on) { 4.months.ago.to_date }

          it "returns error" do
            expect(response).to be_unprocessable
            expect(response.body).to include("The end date must be later than the start date")
          end
        end

        context "when start date is before QTS date" do
          let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }
          let(:induction_period) do
            FactoryBot.create(:induction_period, teacher:, started_on: 9.months.ago, finished_on: 6.months.ago)
          end

          let(:started_on) { 2.years.ago.to_date }
          let(:finished_on) { 4.months.ago.to_date }

          it "returns error" do
            expect(response).to be_unprocessable
            expect(response.body).to include("Start date cannot be before QTS award date")
          end
        end
      end
    end

    context "when induction period has an outcome" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, teacher:,
                                             started_on: 9.months.ago,
                                             finished_on: 6.months.ago,
                                             outcome: "pass",
                                             number_of_terms: 3)
      end

      context "when updating dates" do
        let(:started_on) { 8.months.ago.to_date }
        let(:finished_on) { 5.months.ago.to_date }

        before do
          allow(PassECTInductionJob).to receive(:perform_later)
        end

        it "updates all fields" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).to redirect_to(ab_teacher_path(induction_period.teacher))
          expect(flash[:alert]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.started_on).to eq(started_on)
          expect(induction_period.finished_on).to eq(finished_on)
          expect(induction_period.number_of_terms).to eq(number_of_terms)
          expect(induction_period.induction_programme).to eq(induction_programme)
          expect(induction_period.training_programme).to eq('provider_led')
        end

        it "notifies TRS of the updated dates" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(PassECTInductionJob).to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: started_on,
            completed_date: finished_on,
            pending_induction_submission_id: nil
          )
        end
      end

      context "when only updating number of terms" do
        let(:params) do
          { induction_period: { number_of_terms: } }
        end

        it "updates the number of terms" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).to redirect_to(ab_teacher_path(induction_period.teacher))
          expect(flash[:alert]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.number_of_terms).to eq(number_of_terms)
        end
      end

      context "when only updating induction programme" do
        let(:params) do
          { induction_period: { induction_programme: } }
        end

        it "updates the induction programme" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).to redirect_to(ab_teacher_path(induction_period.teacher))
          expect(flash[:alert]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.induction_programme).to eq(induction_programme)
          expect(induction_period.training_programme).to eq('provider_led')
        end
      end
    end

    context "when induction period has a fail outcome" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, teacher:,
                                             started_on: 9.months.ago,
                                             finished_on: 6.months.ago,
                                             outcome: "fail",
                                             number_of_terms: 3)
      end

      context "when only updating end date" do
        let(:params) do
          { induction_period: { finished_on: } }
        end

        let(:finished_on) { 5.months.ago.to_date }

        before do
          allow(FailECTInductionJob).to receive(:perform_later)
        end

        it "updates the end date" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).to redirect_to(ab_teacher_path(induction_period.teacher))
          expect(flash[:alert]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.finished_on).to eq(finished_on)
        end

        it "notifies TRS of the updated end date" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(FailECTInductionJob).to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: induction_period.started_on,
            completed_date: finished_on,
            pending_induction_submission_id: nil
          )
        end
      end
    end
  end
end
