RSpec.describe 'appropriate_bodies/teachers/show.html.erb' do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    FactoryBot.create(:induction_period, teacher:, appropriate_body:, started_on: 24.months.ago, finished_on: 12.months.ago)
    FactoryBot.create(:induction_period, teacher:, appropriate_body:, started_on: 11.months.ago, finished_on: 3.months.ago)

    assign(:teacher, teacher)
    assign(:appropriate_body, appropriate_body)
  end

  it 'shows a list of past induction periods' do
    render

    expect(rendered).to have_css('ul#past-induction-periods li', count: 2)
  end

  it "the past induction periods don't have edit links" do
    render

    past_induction_period_list = rendered.html.at('ul#past-induction-periods')

    expect(past_induction_period_list).not_to have_link('Edit')
  end
end
