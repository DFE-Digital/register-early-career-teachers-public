RSpec.describe TimelineComponent, type: :component do
  let(:component) { TimelineComponent.new(events) }

  let(:one_day_ago) { build(:event, :with_body, created_at: 1.day.ago) }
  let(:two_days_ago) { build(:event, :with_body, created_at: 2.days.ago) }
  let(:three_days_ago) { build(:event, :with_body, created_at: 3.days.ago) }
  let(:events) { [two_days_ago, one_day_ago, three_days_ago] }

  before { render_inline(component) }

  it "displays all of the events in a timeline" do
    expect(rendered_content).to have_css(".app-timeline__item", count: events.size)
  end

  it "shows a timestamp for each event" do
    events.each do |event|
      expect(rendered_content).to have_css("time", text: event.happened_at.to_fs(:govuk_short))
      expect(rendered_content).to have_css("time[datetime='#{event.happened_at.to_fs(:iso8601)}']")
    end
  end

  it "shows the title and byline in the header" do
    events.each do |event|
      expect(rendered_content).to have_css(".app-timeline__header > .app-timeline__title", text: event.heading)
      expect(rendered_content).to have_css(".app-timeline__header > .app-timeline__byline", text: event.author_name)
    end
  end

  it "shows the body for each event" do
    events.each do |event|
      expect(rendered_content).to have_css(".app-timeline__item > .app-timeline__description", text: event.body)
    end
  end

  describe 'modifications' do
    context 'when modifications are present' do
      let(:one_day_ago) { build(:event, :with_body, :with_modifications, created_at: 3.days.ago) }

      it "renders a 'Changes' heading" do
        expect(rendered_content).to have_css('h3', text: 'Changes')
      end

      it "lists modifications when they're present" do
        expect(rendered_content).to have_css('.govuk-list', text: 'Something has changed')
      end
    end

    context 'when no modifications are present' do
      it "renders no heading" do
        expect(rendered_content).not_to have_css('h3', text: 'Changes')
      end

      it "renders no list" do
        expect(rendered_content).not_to have_css('.govuk-list')
      end
    end
  end
end
