RSpec.describe "Admin::InductionPeriods", type: :request do
  include ActionView::Helpers::SanitizeHelper
  include_context 'sign in as DfE user'

  let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe "POST /admin/teachers/:teacher_id/induction-periods" do
    let(:valid_params) do
      {
        induction_period: {
          started_on: 6.months.ago,
          finished_on: 3.months.ago,
          induction_programme: 'fip',
          appropriate_body_id: appropriate_body.id,
          number_of_terms: 2
        }
      }
    end

    context "with valid parameters" do
      it "creates a new induction period" do
        expect {
          post admin_teacher_induction_periods_path(teacher), params: valid_params
        }.to change(InductionPeriod, :count).by(1)
      end

      it "redirects to the teacher page with success message" do
        post admin_teacher_induction_periods_path(teacher), params: valid_params
        expect(response).to redirect_to(admin_teacher_path(teacher))
        expect(flash[:alert]).to eq('Induction period created successfully')
      end

      it "records an 'admin creates induction period' event" do
        allow(Events::Record).to receive(:record_induction_period_opened_event!).once.and_call_original

        post admin_teacher_induction_periods_path(teacher), params: valid_params

        expect(Events::Record).to have_received(:record_induction_period_opened_event!).once.with(
          hash_including(
            {
              appropriate_body:,
              author: kind_of(Sessions::User),
              induction_period: kind_of(InductionPeriod),
              teacher:,
            }
          )
        )
      end

      it "creates the period with correct attributes" do
        post admin_teacher_induction_periods_path(teacher), params: valid_params
        period = InductionPeriod.last
        expect(period.started_on).to eq(valid_params[:induction_period][:started_on].to_date)
        expect(period.finished_on).to eq(valid_params[:induction_period][:finished_on].to_date)
        expect(period.induction_programme).to eq(valid_params[:induction_period][:induction_programme])
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          induction_period: {
            started_on: nil,
            finished_on: 1.year.ago + 6.months,
            induction_programme: 'fip',
            appropriate_body_id: appropriate_body.id,
            number_of_terms: 2
          }
        }
      end

      it "does not create a new induction period" do
        expect {
          post admin_teacher_induction_periods_path(teacher), params: invalid_params
        }.not_to change(InductionPeriod, :count)
      end

      it "renders the new template with unprocessable_entity status" do
        post admin_teacher_induction_periods_path(teacher), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Add induction period for")
      end

      it "shows validation errors" do
        post admin_teacher_induction_periods_path(teacher), params: invalid_params
        expect(response.body).to include("Enter a start date")
      end
    end

    context "with overlapping dates" do
      let!(:existing_period) do
        FactoryBot.create(:induction_period,
                          teacher:,
                          started_on: 6.months.ago,
                          finished_on: 3.months.ago)
      end

      let(:overlapping_params) do
        {
          induction_period: {
            started_on: 4.months.ago,
            finished_on: 1.month.ago,
            induction_programme: 'fip',
            appropriate_body_id: appropriate_body.id,
            number_of_terms: 2
          }
        }
      end

      it "does not create a new induction period" do
        expect {
          post admin_teacher_induction_periods_path(teacher), params: overlapping_params
        }.not_to change(InductionPeriod, :count)
      end

      it "renders the new template with unprocessable_entity status" do
        post admin_teacher_induction_periods_path(teacher), params: overlapping_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Add induction period for")
      end

      it "shows validation errors" do
        post admin_teacher_induction_periods_path(teacher), params: overlapping_params
        expect(response.body).to include("Start date cannot overlap another induction period")
      end
    end

    context "with invalid appropriate body" do
      let(:params) do
        {
          induction_period: valid_params[:induction_period].merge(appropriate_body_id: nil)
        }
      end

      it "does not create a new induction period" do
        expect {
          post admin_teacher_induction_periods_path(teacher), params:
        }.not_to change(InductionPeriod, :count)
      end

      it "returns unprocessable_entity status" do
        post(admin_teacher_induction_periods_path(teacher), params:)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Add induction period for")
      end

      it "shows appropriate error message" do
        post(admin_teacher_induction_periods_path(teacher), params:)
        expect(response.body).to include("Select an appropriate body")
      end
    end

    context "with start date before QTS award date" do
      let(:params) do
        {
          induction_period: valid_params[:induction_period].merge(
            started_on: teacher.trs_qts_awarded_on - 1.day
          )
        }
      end

      it "does not create a new induction period" do
        expect {
          post admin_teacher_induction_periods_path(teacher), params:
        }.not_to change(InductionPeriod, :count)
      end

      it "returns unprocessable_entity status" do
        post(admin_teacher_induction_periods_path(teacher), params:)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Add induction period for")
      end

      it "shows appropriate error message" do
        post(admin_teacher_induction_periods_path(teacher), params:)
        expect(response.body).to include("Start date cannot be before QTS award date")
      end
    end

    context "with end date before start date" do
      let(:params) do
        {
          induction_period: valid_params[:induction_period].merge(
            finished_on: valid_params[:induction_period][:started_on] - 1.day
          )
        }
      end

      it "does not create a new induction period" do
        expect {
          post admin_teacher_induction_periods_path(teacher), params:
        }.not_to change(InductionPeriod, :count)
      end

      it "returns unprocessable_entity status" do
        post(admin_teacher_induction_periods_path(teacher), params:)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Add induction period for")
      end

      it "shows appropriate error message" do
        post(admin_teacher_induction_periods_path(teacher), params:)
        expect(response.body).to include("The end date must be later than the start date")
      end
    end

    context "with multiple induction periods" do
      before do
        FactoryBot.create(:induction_period,
                          teacher:,
                          started_on: 9.months.ago,
                          finished_on: 6.months.ago,
                          induction_programme: "fip")
      end

      it "creates a new induction period" do
        expect {
          post admin_teacher_induction_periods_path(teacher), params: valid_params
        }.to change(InductionPeriod, :count).by(1)
      end

      it "creates the period with correct attributes" do
        post admin_teacher_induction_periods_path(teacher), params: valid_params
        period = InductionPeriod.last
        expect(period.started_on).to eq(valid_params[:induction_period][:started_on].to_date)
        expect(period.finished_on).to eq(valid_params[:induction_period][:finished_on].to_date)
        expect(period.induction_programme).to eq(valid_params[:induction_period][:induction_programme])
      end
    end
  end

  describe "GET /admin/teachers/:teacher_id/induction-periods/new" do
    it "renders the new template" do
      get new_admin_teacher_induction_period_path(teacher)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Add induction period for")
    end

    it "shows the form" do
      get new_admin_teacher_induction_period_path(teacher)
      expect(response.body).to include("Which appropriate body was this induction period completed with")
      expect(response.body).to include("Start date")
      expect(response.body).to include("End date")
      expect(response.body).to include("Number of terms")
      expect(response.body).to include("Induction programme")
    end
  end

  describe "GET /admin/teachers/:teacher_id/induction-periods/:id/edit" do
    let(:induction_period) { FactoryBot.create(:induction_period, teacher:, started_on: 9.months.ago, finished_on: 6.months.ago) }

    it "returns success" do
      get edit_admin_teacher_induction_period_path(induction_period.teacher, induction_period)
      expect(response).to be_successful
    end
  end

  describe "PATCH /admin/teachers/:teacher_id/induction-periods/:id" do
    context "when induction period has no outcome" do
      let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, started_on: 9.months.ago, finished_on: 6.months.ago) }

      context "with valid params" do
        let(:valid_params) do
          {
            induction_period: {
              started_on: 5.months.ago,
              finished_on: 3.months.ago,
              number_of_terms: 1,
              induction_programme: "cip",
              appropriate_body_id: appropriate_body.id
            }
          }
        end

        it "updates the induction period" do
          patch admin_teacher_induction_period_path(induction_period.teacher, induction_period), params: valid_params

          expect(response).to redirect_to(admin_teacher_path(induction_period.teacher))
          expect(flash[:alert]).to eq("Induction period updated successfully")

          induction_period.reload
          expect(induction_period.started_on).to eq(valid_params[:induction_period][:started_on].to_date)
          expect(induction_period.finished_on).to eq(valid_params[:induction_period][:finished_on].to_date)
          expect(induction_period.number_of_terms).to eq(valid_params[:induction_period][:number_of_terms])
          expect(induction_period.induction_programme).to eq(valid_params[:induction_period][:induction_programme])
          expect(induction_period.appropriate_body).to eq(appropriate_body)
        end

        it "records an 'admin updates induction period' event" do
          allow(Events::Record).to receive(:record_admin_updates_induction_period!).once.and_call_original

          induction_period.assign_attributes(valid_params[:induction_period])
          expected_modifications = induction_period.changes

          patch admin_teacher_induction_period_path(induction_period.teacher, induction_period), params: valid_params

          expect(Events::Record).to have_received(:record_admin_updates_induction_period!).once.with(
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
          let!(:first_period) do
            FactoryBot.create(:induction_period,
                              teacher:,
                              started_on: 1.year.ago,
                              finished_on: 8.months.ago,
                              induction_programme: "cip")
          end

          let(:induction_period) do
            FactoryBot.create(:induction_period,
                              teacher:,
                              started_on: 6.months.ago,
                              finished_on: 3.months.ago)
          end

          let(:params) do
            {
              induction_period: {
                started_on: 9.months.ago,
                finished_on: 3.months.ago
              }
            }
          end

          it "returns error" do
            patch(admin_teacher_induction_period_path(induction_period.teacher, induction_period), params:)
            expect(response).not_to redirect_to(admin_teacher_path(induction_period.teacher))
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include("Start date cannot overlap another induction period")
          end
        end

        context "when updating earliest period start date" do
          let!(:earliest_period) do
            FactoryBot.create(:induction_period,
                              teacher:,
                              started_on: 12.months.ago,
                              finished_on: 9.months.ago)
          end

          let(:params) do
            {
              induction_period: {
                started_on: 11.months.ago,
                finished_on: 9.months.ago
              }
            }
          end

          before do
            allow(BeginECTInductionJob).to receive(:perform_later)
            teacher.induction_periods.started_before(earliest_period.started_on).destroy_all
          end

          it "enqueues BeginECTInductionJob" do
            patch(admin_teacher_induction_period_path(teacher, earliest_period), params:)
            expect(BeginECTInductionJob).to have_received(:perform_later).with(
              trn: teacher.trn,
              start_date: params[:induction_period][:started_on].to_date
            )
          end
        end
      end

      context "with invalid params" do
        context "when start date is after end date" do
          let(:invalid_params) do
            {
              induction_period: {
                started_on: 3.months.ago,
                finished_on: 4.months.ago,
                appropriate_body_id: appropriate_body.id
              }
            }
          end

          it "returns error" do
            patch admin_teacher_induction_period_path(induction_period.teacher, induction_period), params: invalid_params
            expect(response).to be_unprocessable
            expect(response.body).to include("The end date must be later than the start date")
          end
        end

        context "when start date is before QTS date" do
          let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }
          let(:induction_period) { FactoryBot.create(:induction_period, teacher:, started_on: 9.months.ago, finished_on: 6.months.ago) }

          it "returns error" do
            patch admin_teacher_induction_period_path(induction_period.teacher, induction_period), params: {
              induction_period: { started_on: 2.years.ago, appropriate_body_id: appropriate_body.id }
            }
            expect(response).to be_unprocessable
            expect(response.body).to include("Start date cannot be before QTS award date")
          end
        end
      end
    end
  end
end
