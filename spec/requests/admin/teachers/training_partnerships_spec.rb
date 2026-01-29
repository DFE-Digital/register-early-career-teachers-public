RSpec.describe "Admin::Teachers::TrainingPartnerships", type: :request do
  include_context "sign in as DfE user"

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:other_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, school:, lead_provider:, delivery_partner:) }
  let!(:other_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, school:, lead_provider: other_lead_provider, delivery_partner: other_delivery_partner) }
  let(:ect_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: school_partnership.contract_period) }
  let(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period: ect_period, school_partnership:, schedule:) }
  let(:teacher_name) { Teachers::Name.new(teacher).full_name }

  describe "GET /admin/teachers/:teacher_id/training_periods/:training_period_id/partnership/new" do
    it "renders the partnership selection page" do
      get new_admin_teacher_training_period_partnership_path(teacher, training_period)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Select a partnership for #{teacher_name}")
      expect(response.body).to include("#{other_school_partnership.lead_provider.name} &amp; #{other_school_partnership.delivery_partner.name}")
      expect(response.body).to include("If you need to add a new partnership, go to")
    end

    context "when no other school partnerships exist" do
      let!(:other_school_partnership) { nil }

      it "renders the no other partnerships page when there are no alternatives" do
        get new_admin_teacher_training_period_partnership_path(teacher, training_period)
        expect(response).to redirect_to(no_other_partnerships_admin_teacher_training_period_partnership_path(teacher, training_period))

        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(response.body).to include("There are no other partnerships set up")
        expect(response.body).to include("You need to add another partnership for #{school.name} before you can move #{teacher_name}.")
        expect(response.body).to include(admin_school_partnerships_path(school.urn))
      end
    end

    it "returns bad request when the training period is not eligible" do
      training_period.update!(finished_on: Date.current)

      get new_admin_teacher_training_period_partnership_path(teacher, training_period)

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /admin/teachers/:teacher_id/training_periods/:training_period_id/partnership" do
    it "validates the selection" do
      post admin_teacher_training_period_partnership_path(teacher, training_period),
           params: { admin_teachers_change_training_partnership_form: { school_partnership_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select a partnership")
    end

    it "updates the partnership for a future training period and records an event" do
      training_period.update!(started_on: 2.weeks.from_now.to_date)
      expect {
        perform_enqueued_jobs do
          post admin_teacher_training_period_partnership_path(teacher, training_period),
               params: { admin_teachers_change_training_partnership_form: { school_partnership_id: other_school_partnership.id } }
        end
      }.to change { Event.where(event_type: "training_period_assigned_to_school_partnership").count }.by(1)
      expect(response).to redirect_to(admin_teacher_training_path(teacher))
      expect(flash[:alert]).to eq("Partnership updated")

      expect(training_period.reload.school_partnership_id).to eq(other_school_partnership.id)
      expect(training_period.expression_of_interest).to be_nil
    end

    it "ends a current training period and creates a new one with the selected partnership" do
      training_period.update!(started_on: 2.days.ago.to_date)

      expect {
        perform_enqueued_jobs do
          post admin_teacher_training_period_partnership_path(teacher, training_period),
               params: { admin_teachers_change_training_partnership_form: { school_partnership_id: other_school_partnership.id } }
        end
      }.to change(TrainingPeriod, :count).by(1)
         .and change { Event.where(event_type: "training_period_assigned_to_school_partnership").count }.by(1)
         .and change { Event.where(event_type: "teacher_finishes_training_period").count }.by(1)

      expect(response).to redirect_to(admin_teacher_training_path(teacher))
      expect(flash[:alert]).to eq("Partnership updated")

      training_period.reload
      expect(training_period.finished_on).to eq(Date.current)

      replacement = TrainingPeriod.order(:created_at).last
      expect(replacement.school_partnership).to eq(other_school_partnership)
      expect(replacement.expression_of_interest).to be_nil
      expect(replacement.started_on).to eq(Date.current)
      expect(replacement.finished_on).to be_nil
    end

    it "updates a training period that starts today without creating a new one" do
      training_period.update!(started_on: Date.current)
      expect {
        perform_enqueued_jobs do
          post admin_teacher_training_period_partnership_path(teacher, training_period),
               params: { admin_teachers_change_training_partnership_form: { school_partnership_id: other_school_partnership.id } }
        end
      }.to not_change(TrainingPeriod, :count)
         .and change { Event.where(event_type: "training_period_assigned_to_school_partnership").count }.by(1)

      expect(response).to redirect_to(admin_teacher_training_path(teacher))
      expect(flash[:alert]).to eq("Partnership updated")

      training_period.reload
      expect(training_period.school_partnership).to eq(other_school_partnership)
      expect(training_period.expression_of_interest).to be_nil
      expect(training_period.finished_on).to be_nil
    end

    it "returns bad request when the training period is not eligible" do
      training_period.update!(finished_on: Date.current)

      post admin_teacher_training_period_partnership_path(teacher, training_period),
           params: { admin_teachers_change_training_partnership_form: { school_partnership_id: other_school_partnership.id } }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
