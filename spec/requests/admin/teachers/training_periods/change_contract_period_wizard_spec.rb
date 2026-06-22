RSpec.describe "Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizardController", type: :request do
  include_context "sign in as DfE user"
  include HaveSummaryListRow

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
  let!(:target_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: target_contract_period.year,
      school:,
      lead_provider: school_partnership.lead_provider,
      delivery_partner: school_partnership.delivery_partner
    )
  end
  let(:different_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: target_contract_period.year,
      school:
    )
  end
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let(:target_schedule) { FactoryBot.create(:schedule, contract_period: target_contract_period, identifier: schedule.identifier) }
  let(:eoi_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: eoi_lead_provider, contract_period: current_contract_period) }
  let!(:target_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: eoi_lead_provider, contract_period: target_contract_period) }
  let(:eoi_only_training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      :with_only_expression_of_interest,
      ect_at_school_period:,
      expression_of_interest: active_lead_provider,
      schedule:,
      started_on: today.prev_month
    )
  end
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
  let(:replacement_training_periods) { TrainingPeriod.where(ect_at_school_period:).where.not(id: training_period.id) }
  let(:replacement_training_period) { replacement_training_periods.sole }
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

    it "returns bad request when the training period starts in the future" do
      training_period.update!(started_on: today.next_month, finished_on: nil)

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

    context "when there are no partnerships for the current lead provider and delivery partner" do
      let(:target_school_partnership) { nil }

      it "redirects to the no partnerships page" do
        post(
          path_for_step("select-contract-period"),
          params: { select_contract_period: { contract_period_year: target_contract_period.year } }
        )

        expect(response).to redirect_to(path_for_step("no-partnerships"))
      end
    end

    context "when the current period only has an expression of interest" do
      let(:training_period) { eoi_only_training_period }

      it "redirects to check answers" do
        post(
          path_for_step("select-contract-period"),
          params: { select_contract_period: { contract_period_year: target_contract_period.year } }
        )

        expect(response).to redirect_to(path_for_step("check-answers"))
      end
    end
  end

  describe "GET select-partnership" do
    it "redirects to select contract period when no contract period has been selected" do
      get path_for_step("select-partnership")

      expect(response).to redirect_to(path_for_step("select-contract-period"))
    end

    it "renders the partnership selection page after a contract period has been selected" do
      target_school_partnership
      partnership_name =
        "#{target_school_partnership.lead_provider.name} & #{target_school_partnership.delivery_partner.name}"

      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: target_contract_period.year } }
      )
      follow_redirect!
      page = Capybara.string(response.body)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Select #{target_contract_period.year} partnership for #{teacher_name}")
      expect(page).to have_text(partnership_name)
      expect(response.body).to include(admin_school_partnerships_path(school.urn))
    end
  end

  describe "POST select-partnership" do
    it "redirects to check answers when the selection is valid" do
      select_contract_period_and_partnership

      expect(response).to redirect_to(path_for_step("check-answers"))
    end

    it "validates the selected partnership uses the current lead provider and delivery partner" do
      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: target_contract_period.year } }
      )

      post(
        path_for_step("select-partnership"),
        params: { select_partnership: { school_partnership_id: different_school_partnership.id } }
      )

      page = Capybara.string(response.body)

      expect(response).to have_http_status(:unprocessable_content)
      expect(page).to have_text("There is a problem")
      expect(page).to have_text("Select a partnership")
    end
  end

  describe "GET no-partnerships" do
    let(:target_school_partnership) { nil }

    it "renders the no partnerships page after a contract period has been selected" do
      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: target_contract_period.year } }
      )
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("There are no partnerships set up for #{target_contract_period.year}")
      expect(response.body).to include("You need to add a partnership for #{school.name} in the #{target_contract_period.year} contract period before you can change #{teacher_name}’s contract period.")
      expect(response.body).to include(admin_school_partnerships_path(school.urn))
    end
  end

  describe "GET check-answers" do
    it "redirects to select partnership when no partnership has been selected" do
      post(
        path_for_step("select-contract-period"),
        params: { select_contract_period: { contract_period_year: target_contract_period.year } }
      )

      get path_for_step("check-answers")

      expect(response).to redirect_to(path_for_step("select-partnership"))
    end

    it "renders the CYA page after the contract period and partnership have been selected" do
      select_contract_period_and_partnership

      get path_for_step("check-answers")
      page = Capybara.string(response.body)
      partnership_name =
        "#{target_school_partnership.lead_provider.name} & #{target_school_partnership.delivery_partner.name}"

      expect(response).to have_http_status(:ok)
      expect(page).to have_text("Confirm contract period change for #{teacher_name}")
      expect(page).to have_summary_list_row("Existing contract period", value: current_contract_period.year.to_s)
      expect(page).to have_summary_list_row("New contract period", value: target_contract_period.year.to_s)
      expect(page).to have_summary_list_row("Partnership", value: partnership_name)
    end

    context "when the current period only has an expression of interest" do
      let(:eoi_lead_provider) { FactoryBot.create(:lead_provider, name: "Target Lead Provider") }
      let(:training_period) { eoi_only_training_period }

      it "renders the CYA page after the contract period has been selected" do
        post(
          path_for_step("select-contract-period"),
          params: { select_contract_period: { contract_period_year: target_contract_period.year } }
        )

        get path_for_step("check-answers")
        page = Capybara.string(response.body)

        expect(response).to have_http_status(:ok)
        expect(page).to have_text("Confirm contract period change for #{teacher_name}")
        expect(page).to have_summary_list_row("Existing contract period", value: current_contract_period.year.to_s)
        expect(page).to have_summary_list_row("New contract period", value: target_contract_period.year.to_s)
        expect(page).to have_summary_list_row("Lead provider", value: "Target Lead Provider")
        expect(page).to have_summary_list_row("Delivery partner", value: "No delivery partner confirmed")
      end
    end
  end

  describe "POST check-answers" do
    it "applies the contract period change and redirects to the training tab" do
      target_school_partnership
      target_schedule
      select_contract_period_and_partnership

      expect {
        post path_for_step("check-answers"), params: { check_answers: {} }
      }.to change { TrainingPeriod.where(ect_at_school_period:).count }.by(1)

      expect(response).to redirect_to(admin_teacher_training_path(teacher))
      expect(training_period.reload.finished_on).to eq(today.yesterday)
      expect(replacement_training_period.contract_period).to eq(target_contract_period)
      expect(replacement_training_period.school_partnership).to eq(target_school_partnership)
      expect(replacement_training_period.schedule).to eq(target_schedule)

      follow_redirect!

      expect(response.body).to include("Contract period changed")
    end

    it "shows an error when the selected contract period has no matching schedule" do
      target_school_partnership
      select_contract_period_and_partnership

      expect {
        post path_for_step("check-answers"), params: { check_answers: {} }
      }.not_to change(TrainingPeriod, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("A matching schedule could not be found for the selected contract period")
    end

    context "when the current period only has an expression of interest" do
      let(:training_period) { eoi_only_training_period }

      it "creates a replacement expression of interest only training period" do
        target_schedule

        post(
          path_for_step("select-contract-period"),
          params: { select_contract_period: { contract_period_year: target_contract_period.year } }
        )

        expect {
          post path_for_step("check-answers"), params: { check_answers: {} }
        }.to change { TrainingPeriod.where(ect_at_school_period:).count }.by(1)

        expect(response).to redirect_to(admin_teacher_training_path(teacher))
        expect(training_period.reload.finished_on).to eq(today.yesterday)
        expect(replacement_training_period.school_partnership).to be_nil
        expect(replacement_training_period.expression_of_interest).to eq(target_active_lead_provider)
        expect(replacement_training_period.expression_of_interest_contract_period).to eq(target_contract_period)
        expect(replacement_training_period.schedule).to eq(target_schedule)
      end
    end
  end

private

  def path_for_step(step, teacher: self.teacher, training_period: self.training_period)
    "/admin/teachers/#{teacher.id}/training-periods/#{training_period.id}/contract-period/change/#{step}"
  end

  def select_contract_period_and_partnership
    post(
      path_for_step("select-contract-period"),
      params: { select_contract_period: { contract_period_year: target_contract_period.year } }
    )

    post(
      path_for_step("select-partnership"),
      params: { select_partnership: { school_partnership_id: target_school_partnership.id } }
    )
  end
end
