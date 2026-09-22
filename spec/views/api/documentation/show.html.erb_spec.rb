describe "api/documentation/show.html.erb" do
  subject { rendered }

  before { render }

  it { is_expected.to have_css("h1", text: "Register early career teachers APIs") }

  it { is_expected.to have_css("h2", text: "Authentication") }
  it { is_expected.to have_link("Read the authentication guidance", href: "#authentication") }

  it { is_expected.to have_css("h2", text: "Hello World API") }
  it { is_expected.to have_link("View the Hello World API", href: "#hello-world") }

  it { is_expected.to have_css("h2", text: "Training API") }
  it { is_expected.to have_link("View the Training API", href: api_docs_training_guidance_path) }

  it { is_expected.to have_css("h2", text: "Induction API") }
  it { is_expected.to have_link("View the Induction API", href: "#induction") }
end
