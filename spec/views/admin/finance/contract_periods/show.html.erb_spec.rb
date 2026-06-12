RSpec.describe "admin/finance/contract_periods/show.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period) }

  before do
    assign(:contract_period, contract_period)
    assign(:editable, !contract_period.started_on_or_before_today?)
    assign(:has_lead_providers, contract_period.active_lead_providers.any?)
    assign(:has_schedules, contract_period.schedules.any?)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => nil,
    })
  end

  it "has the page title 'Contract period <year>'" do
    render

    expect(view.content_for(:page_title)).to eq("#{contract_period.year} contract period")
  end

  it "renders the breadcrumbs" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to include(contract_period.year.to_s)
  end

  it "renders a summary list with the contract period attributes" do
    render

    expect(rendered).to have_css(".govuk-summary-list")
    expect(rendered).to have_content("Year")
    expect(rendered).to have_content(contract_period.year.to_s)
    expect(rendered).to have_content("Started on")
    expect(rendered).to have_content(contract_period.started_on.to_fs(:govuk))
    expect(rendered).to have_content("Finished on")
    expect(rendered).to have_content(contract_period.finished_on.to_fs(:govuk))
    expect(rendered).to have_content("Mentor funding enabled")
    expect(rendered).to have_content("Detailed evidence types enabled")
    expect(rendered).to have_content("Uplift fees enabled")
    expect(rendered).to have_content("Payments frozen")
  end

  it "renders a task list" do
    render

    expect(rendered).to have_css(".govuk-task-list")
    expect(rendered).to have_content("Lead providers")
    expect(rendered).to have_content("Schedules")
  end

  describe "edit button" do
    context "when the contract period has not yet started" do
      let(:contract_period) do
        FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
      end

      it "renders an enabled edit button" do
        render

        expect(rendered).to have_link("Edit contract period")
      end
    end

    context "when the contract period has already started" do
      let(:contract_period) do
        FactoryBot.create(:contract_period, year: 2020, started_on: Date.new(2020, 6, 1), finished_on: Date.new(2021, 5, 31))
      end

      it "renders the edit button in a disabled state" do
        render

        expect(rendered).to have_selector("a[disabled], a[aria-disabled='true']", text: "Edit contract period")
      end
    end
  end

  describe "lead providers task" do
    context "when the contract period has not yet started and has no active lead providers" do
      let(:contract_period) do
        FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
      end

      it "shows the task as incomplete with a blue tag and selectable" do
        render

        expect(rendered).to have_link("Lead providers")
        within(".govuk-task-list") do
          expect(rendered).to have_css(".govuk-tag.govuk-tag--blue", text: "Incomplete")
        end
      end
    end

    context "when the contract period has not yet started and has active lead providers" do
      let(:contract_period) do
        FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
      end

      before do
        FactoryBot.create(:active_lead_provider, contract_period:)
      end

      it "shows the task as completed and selectable" do
        render

        expect(rendered).to have_link("Lead providers")
        within(".govuk-task-list") do
          expect(rendered).to have_content("Completed")
        end
      end
    end

    context "when the contract period has started and has active lead providers" do
      let(:contract_period) do
        FactoryBot.create(:contract_period, year: 2020, started_on: Date.new(2020, 6, 1), finished_on: Date.new(2021, 5, 31))
      end

      before do
        FactoryBot.create(:active_lead_provider, contract_period:)
      end

      it "shows the task as completed and selectable" do
        render

        expect(rendered).to have_link("Lead providers")
        within(".govuk-task-list") do
          expect(rendered).to have_content("Completed")
        end
      end
    end
  end

  describe "schedules task" do
    context "when the contract period has no schedules" do
      it "shows the task as cannot start yet" do
        render

        expect(rendered).not_to have_link("Schedules")
        within(".govuk-task-list") do
          expect(rendered).to have_content("Schedules")
          expect(rendered).to have_css(".govuk-task-list__status--cannot-start-yet", text: "Cannot start yet")
        end
      end
    end

    context "when the contract period has schedules" do
      let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules) }

      it "shows the task as completed and links to it" do
        render

        expect(rendered).to have_link("Schedules")
        within(".govuk-task-list") do
          expect(rendered).to have_content("Completed")
        end
      end
    end
  end
end
