describe Migration::MigratedRecordCountsComponent, type: :component do
  before do
    allow(ECTAtSchoolPeriod).to receive(:count).and_return(100_000)
    allow(MentorAtSchoolPeriod).to receive(:count).and_return(200_000)
    allow(MentorshipPeriod).to receive(:count).and_return(300_000)
    allow(TrainingPeriod).to receive(:count).and_return(400_000)

    render_inline(Migration::MigratedRecordCountsComponent.new)
  end

  it "renders a summary list" do
    expect(page).to have_css(".govuk-summary-list")
  end

  it "renders a summary list displaying formatted counts" do
    aggregate_failures do
      expect(page).to have_css(".govuk-summary-list__row", text: /ECTAtSchoolPeriod.*100,000/)
      expect(page).to have_css(".govuk-summary-list__row", text: /MentorAtSchoolPeriod.*200,000/)
      expect(page).to have_css(".govuk-summary-list__row", text: /MentorshipPeriod.*300,000/)
      expect(page).to have_css(".govuk-summary-list__row", text: /TrainingPeriod.*400,000/)
    end
  end
end
