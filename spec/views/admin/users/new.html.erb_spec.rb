describe "admin/users/new.html.erb" do
  let(:role) { :admin }
  let(:user) { User.new }
  let(:otp_school_sign_in_enabled) { false }

  before do
    allow(Rails.application.config).to receive(:enable_otp_school_sign_in).and_return(otp_school_sign_in_enabled)
    assign(:user, user)
    render
  end

  it "shows add a new DfE staff member in the header" do
    expect(view.content_for(:page_header)).to have_css("h1", text: "Add a new DfE staff member")
  end

  it "includes a back link to admin users list" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_users_path)
  end

  it "contains a form that targets the users path" do
    expect(rendered).to have_css(%(form[action='#{admin_users_path}']))
  end

  it "displays a form with name, email and role fields" do
    expect(rendered).to have_css("label", text: "Name")
    expect(rendered).to have_css("label", text: "Email address")
    expect(rendered).to have_css("legend", text: "Role")
  end

  it "does not display an otp_school_urn field when otp school sign-in flag is disabled" do
    expect(rendered).not_to have_css("label", text: "School URN for OTP sign-in")
  end

  it "lists the roles as options" do
    expect(rendered).to have_css("label.govuk-radios__label", text: "Admin")
    expect(rendered).to have_css("label.govuk-radios__label", text: "User manager")
    expect(rendered).to have_css("label.govuk-radios__label", text: "Finance")
  end

  it "has an add user button" do
    expect(rendered).to have_css("button", text: "Add user")
  end

  context "when the user has errors" do
    let(:user) { User.new.tap(&:valid?) }

    it "prefixes the page title with error" do
      expect(view.content_for(:page_title)).to start_with("Error:")
    end
  end

  context "when otp school sign-in flag is enabled" do
    let(:otp_school_sign_in_enabled) { true }

    it "displays the otp_school_urn field" do
      expect(rendered).to have_css("label", text: "School URN for OTP sign-in")
    end
  end
end
