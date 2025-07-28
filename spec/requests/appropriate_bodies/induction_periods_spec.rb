RSpec.describe 'Appropriate body editing an active induction period', type: :request do
  include_context 'sign in as non-DfE user'

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }
  let!(:induction_period) do
    FactoryBot.create(:induction_period, :active, teacher:, started_on: 9.months.ago)
  end

  describe "GET /appropriate-body/teachers/:teacher_id/induction-periods/:id/edit" do
    it "returns success" do
      get edit_ab_teacher_induction_period_path(induction_period.teacher, induction_period)
      expect(response).to be_successful
      expect(response.body).to include("Edit induction period")
    end
  end

  describe "PATCH /appropriate-body/teachers/:teacher_id/induction-periods/:id" do
    let(:params) do
      {
        induction_period: {
          started_on:,
          induction_programme:,
          appropriate_body_id: appropriate_body.id
        }
      }
    end

    let(:induction_programme) { "cip" }

    context "with valid params" do
      let(:started_on) { 5.months.ago.to_date }

      it "updates the induction period" do
        patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

        expect(response).to redirect_to(ab_teacher_path(induction_period.teacher))
        expect(flash[:alert]).to eq("Induction period updated successfully")

        induction_period.reload
        expect(induction_period.started_on).to eq(started_on)
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

      context "when ne programme types are enabled" do
        let(:params) do
          {
            induction_period: {
              started_on:,
              training_programme:,
              appropriate_body_id: appropriate_body.id
            }
          }
        end

        let(:training_programme) { "school_led" }

        it "updates the induction period" do
          allow(Rails.application.config).to receive(:enable_bulk_claim).and_return(true)
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).to redirect_to(ab_teacher_path(induction_period.teacher))
          expect(flash[:alert]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.started_on).to eq(started_on)
          expect(induction_period.induction_programme).to eq("unknown")

          expect(induction_period.training_programme).to eq(training_programme)
          expect(induction_period.appropriate_body).to eq(appropriate_body)
        end
      end
    end

    context "with invalid params" do
      context "when start date is before QTS date" do
        let(:started_on) { 2.years.ago.to_date }

        it "returns error" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).to be_unprocessable
          expect(response.body).to include("Start date cannot be before QTS award date")
        end
      end

      context "when dates would cause overlap" do
        before do
          FactoryBot.create(:induction_period, teacher:, started_on: 1.year.ago, finished_on: 9.months.ago)
        end

        let(:started_on) { 10.months.ago.to_date }

        it "returns error" do
          patch(ab_teacher_induction_period_path(induction_period.teacher, induction_period), params:)

          expect(response).not_to redirect_to(ab_teacher_path(induction_period.teacher))
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("Start date cannot overlap another induction period")
        end
      end
    end
  end
end
