describe "otp_sessions/new.html.erb" do
  before { assign(:otp_form, Sessions::OTPSignInForm.new) }

  it "sets the page title to 'Sign in'" do
    render

    expect(view.content_for(:page_title)).to eql("Sign in")
  end

  it "renders an email field with autocomplete='email'" do
    render

    expect(rendered).to have_css("form input[type='email'][autocomplete='email']")
  end

  it "renders a 'Request code to sign in' button" do
    render

    expect(rendered).to have_css("form button", text: "Request code to sign in")
  end
end
