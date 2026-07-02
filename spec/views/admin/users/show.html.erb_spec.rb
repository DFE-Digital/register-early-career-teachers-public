describe "admin/users/show.html.erb" do
  let(:role) { :admin }
  let(:user) { FactoryBot.create(:user, role) }
  let(:otp_school_sign_in_enabled) { false }

  before do
    allow(Rails.application.config).to receive(:enable_otp_school_sign_in).and_return(otp_school_sign_in_enabled)
    assign(:user, user)
    render
  end

  it "includes a back link to admin users list" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_users_path)
  end

  it "shows the name in the h1" do
    expect(view.content_for(:page_header)).to have_css("h1", text: user.name)
  end

  it "displays the full name" do
    expect(rendered).to have_css("dt", text: "Name")
    expect(rendered).to have_css("dd", text: user.name)
  end

  it "displays the email address" do
    expect(rendered).to have_css("dt", text: "Email address")
    expect(rendered).to have_css("dd", text: user.email)
  end

  it "displays the creation date" do
    expect(rendered).to have_css("dt", text: "Created on")
    expect(rendered).to have_css("dd", text: user.created_at.to_date.to_fs(:govuk))
  end

  it "displays the role (admin by default)" do
    expect(rendered).to have_css("dt", text: "Role")
    expect(rendered).to have_css("dd", text: "Admin")
  end

  it "displays whether the account is locked for OTP sign-in" do
    expect(rendered).to have_css("dt", text: "Account locked")
    expect(rendered).to have_css("dd", text: "No")
  end

  it "does not display an unlock OTP sign-in button" do
    expect(rendered).not_to have_button("Unlock OTP sign-in")
  end

  it "does not display the otp school URN row when otp school sign-in flag is disabled" do
    expect(rendered).not_to have_css("dt", text: "School URN for OTP sign-in")
  end

  context "when the user is locked out of OTP sign-in" do
    let(:user) { FactoryBot.create(:user, role, otp_locked_at: Time.zone.now) }

    it "displays that the account is locked for OTP sign-in" do
      expect(rendered).to have_css("dt", text: "Account locked")
      expect(rendered).to have_css("dd", text: "Yes")
    end

    it "displays an unlock OTP sign-in button" do
      expect(rendered).to have_button("Unlock OTP sign-in")
    end
  end

  context "when the user is a user manager user" do
    let(:role) { :user_manager }

    it "displays the user manager role" do
      expect(rendered).to have_css("dt", text: "Role")
      expect(rendered).to have_css("dd", text: "User manager")
    end
  end

  context "when the user is a finance user" do
    let(:role) { :finance }

    it "displays the finance role" do
      expect(rendered).to have_css("dt", text: "Role")
      expect(rendered).to have_css("dd", text: "Finance")
    end
  end

  context "when otp school sign-in flag is enabled" do
    let(:otp_school_sign_in_enabled) { true }

    context "when the user has an otp school URN" do
      let(:user) { FactoryBot.create(:user, role, otp_school_urn: 123_456) }

      it "displays the otp school URN row and value" do
        expect(rendered).to have_css("dt", text: "School URN for OTP sign-in")
        expect(rendered).to have_css("dd", text: user.otp_school_urn.to_s)
      end
    end

    context "when the user has no otp school URN" do
      let(:user) { FactoryBot.create(:user, role, otp_school_urn: nil) }

      it "displays 'Not set' for the otp school URN row" do
        expect(rendered).to have_css("dt", text: "School URN for OTP sign-in")
        expect(rendered).to have_css("dd", text: "Not set")
      end
    end
  end
end
