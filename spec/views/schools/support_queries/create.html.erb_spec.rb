RSpec.describe "schools/support_queries/create.html.erb", :enable_schools_interface do
  subject { rendered }

  before { render }

  it { is_expected.to have_link("Back to ECTs", href: schools_ects_home_path) }
end
