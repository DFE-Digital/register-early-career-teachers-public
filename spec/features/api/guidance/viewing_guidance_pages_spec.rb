RSpec.describe 'Viewing api guidance pages' do
  scenario 'Displaying all the release notes' do
    given_i_am_on_the_api_guidance_page
    when_i_click_page(1)
    then_i_should_be_on_page(1)

    when_i_click_page(2)
    then_i_should_be_on_page(2)

    when_i_click_page(3)
    then_i_should_be_on_page(3)
  end

private

  def given_i_am_on_the_api_guidance_page
    path = '/api/guidance'
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def when_i_click_page(number)
    page.get_by_role('link', name: "Page #{number}").click
  end

  def then_i_should_be_on_page(number)
    expect(page.url).to end_with("/api/guidance/page-#{number}")
  end
end
