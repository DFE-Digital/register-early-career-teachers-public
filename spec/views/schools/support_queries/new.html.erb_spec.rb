RSpec.describe "schools/support_queries/new.html.erb", :enable_schools_interface do
  subject { rendered }

  let(:current_user) { FactoryBot.create(:school_user, :at_random_school) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(current_user)
    end

    assign(:support_query, SupportQuery.new)
    render
  end

  it { is_expected.to have_content(current_user.name) }
  it { is_expected.to have_content(current_user.email) }
  it { is_expected.to have_content(current_user.school.name) }
  it { is_expected.to have_content(current_user.school.urn) }
  it { is_expected.to have_selector("textarea[name='support_query[message]']") }
  it { is_expected.to have_button("Send") }
end
