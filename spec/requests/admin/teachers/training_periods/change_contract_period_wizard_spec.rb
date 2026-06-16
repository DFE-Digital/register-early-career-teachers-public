RSpec.describe "Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizardController", type: :request do
  include_context "sign in as DfE user"

  let(:today) { Date.new(2026, 2, 1) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let!(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: current_contract_period.year,
      school:
    )
  end
  let(:target_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: target_contract_period.year,
      school:
    )
  end
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      ect_at_school_period:,
      school_partnership:,
      schedule:,
      started_on: today.prev_month
    )
  end
  let(:teacher_name) { Teachers::Name.new(teacher).full_name }

  around do |example|
    travel_to(today) { example.run }
  end

  describe "GET select-contract-period" do
    it "renders the contract period selection page" do
      get path_for_step("select-contract-period")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Select new contract period for #{teacher_name}")
      expect(response.body).to include(target_contract_period.year.to_s)
      expect(response.body).not_to include(current_contract_period.year.to_s)
    end

    it "returns not found when the training period does not belong to the teacher" do
      other_teacher = FactoryBot.create(:teacher)

      get path_for_step("select-contract-period", teacher: other_teacher)

      expect(response).to have_http_status(:not_found)
    end

    it "returns bad request when the training period is not eligible" do
      training_period.update!(finished_on: today.yesterday)

      get path_for_step("select-contract-period")

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST select-contract-period" do
    it "validates the selection" do
      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: "" } }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select a new contract period")
    end

    it "validates the selected contract period is available" do
      unavailable_contract_period = FactoryBot.create(:contract_period, year: 2027, enabled: false)

      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: unavailable_contract_period.year } }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select a new contract period")
    end

    it "redirects to select partnership when the selection is valid" do
      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: target_contract_period.year } }
      )

      expect(response).to redirect_to(path_for_step("select-partnership"))
    end
  end

  describe "GET select-partnership" do
    it "redirects to select contract period when no contract period has been selected" do
      get path_for_step("select-partnership")

      expect(response).to redirect_to(path_for_step("select-contract-period"))
    end

    it "renders the partnership selection page after a contract period has been selected" do
      target_school_partnership

      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: target_contract_period.year } }
      )
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Select #{target_contract_period.year} partnership for #{teacher_name}")
      expect(response.body).to include("#{target_school_partnership.lead_provider.name} &amp; #{target_school_partnership.delivery_partner.name}")
      expect(response.body).to include(admin_school_partnerships_path(school.urn))
    end
  end

private

  def path_for_step(step, teacher: self.teacher, training_period: self.training_period)
    "/admin/teachers/#{teacher.id}/training-periods/#{training_period.id}/contract-period/change/#{step}"
  end
end
