RSpec.describe "admin/finance/schedules/show.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-january", contract_period:) }

  before do
    assign(:contract_period, contract_period)
    assign(:schedule, schedule)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      "Schedules" => admin_contract_period_schedules_path(contract_period),
      schedule.name => nil,
    })
  end

  it "has the page title with the schedule name" do
    render
    expect(view.content_for(:page_title)).to eq(schedule.name)
  end

  it "renders the caption with the contract period year" do
    render
    expect(view.content_for(:page_caption)).to have_css(".govuk-caption-l", text: "#{contract_period.year} contract period")
  end

  it "renders the breadcrumbs" do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Schedules", href: admin_contract_period_schedules_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to include(schedule.name)
  end

  context "when the schedule has no milestones" do
    it "displays the empty state message" do
      render
      expect(rendered).to have_text("This schedule currently has no milestones.")
    end

    it "renders an enabled delete schedule button" do
      render
      expect(rendered).to have_button("Delete schedule")
    end

    it "renders an enabled add milestone link" do
      render
      expect(rendered).to have_link("Add milestone",
                                    href: new_admin_contract_period_schedule_milestone_path(contract_period, schedule))
    end
  end

  context "when the schedule has milestones" do
    before do
      FactoryBot.create(:milestone,
                        schedule:,
                        start_date: Date.new(contract_period.year, 9, 1),
                        declaration_type: "started")

      FactoryBot.create(:milestone,
                        schedule:,
                        milestone_date: Date.new(contract_period.year, 10, 1),
                        declaration_type: "retained-1")
    end

    it "renders a table of milestones" do
      render
      expect(rendered).to have_css(".govuk-table")
      expect(rendered).to have_css(".govuk-table__head th", text: "Declaration type")
      expect(rendered).to have_css(".govuk-table__head th", text: "Start date")
      expect(rendered).to have_css(".govuk-table__head th", text: "Milestone date")
    end

    it "lists milestones in declaration order" do
      render
      expect(rendered).to have_text("Started")
      expect(rendered).to have_text("Retained 1")
    end

    it "formats dates" do
      render
      expect(rendered).to have_text("1 September #{contract_period.year}")
      expect(rendered).to have_text("1 October #{contract_period.year}")
    end

    it "disables the delete schedule button" do
      render
      expect(rendered).to have_button("Delete schedule", disabled: true)
    end

    it "renders remove buttons for each milestone" do
      render
      expect(rendered).to have_css(".govuk-button--secondary", count: 2, text: "Remove")
    end

    it "includes visually hidden text on remove buttons" do
      render
      expect(rendered).to have_button("Remove Started")
      expect(rendered).to have_button("Remove Retained 1")
    end
  end

  context "when the contract period has started" do
    let(:contract_period) { FactoryBot.create(:contract_period, :previous) }

    context "and the schedule has no milestones" do
      it "disables the add milestone button" do
        render
        expect(rendered).to have_button("Add milestone", disabled: true)
      end

      it "still enables the delete schedule button" do
        render
        expect(rendered).to have_button("Delete schedule")
      end
    end

    context "and the schedule has milestones" do
      before do
        FactoryBot.create(:milestone, schedule:, declaration_type: "started")
      end

      it "disables the remove milestone buttons" do
        render
        expect(rendered).to have_button("Remove Started", disabled: true)
      end

      it "disables the add milestone button" do
        render
        expect(rendered).to have_button("Add milestone", disabled: true)
      end

      it "disables the delete schedule button" do
        render
        expect(rendered).to have_button("Delete schedule", disabled: true)
      end
    end
  end

  context "when the schedule is fully milestoned" do
    before do
      Milestone.declaration_types.each_value do |declaration_type|
        FactoryBot.create(:milestone, schedule:, declaration_type:)
      end
    end

    it "disables the add milestone button" do
      render
      expect(rendered).to have_button("Add milestone", disabled: true)
    end

    it "disables the delete schedule button" do
      render
      expect(rendered).to have_button("Delete schedule", disabled: true)
    end
  end
end
