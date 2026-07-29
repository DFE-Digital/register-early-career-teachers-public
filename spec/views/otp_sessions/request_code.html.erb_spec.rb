describe "otp_sessions/request_code.html.erb" do
  before { assign(:otp_form, Sessions::OTPSignInForm.new(email: "hello@example.com")) }

  it "sets the page title to 'Enter your code'" do
    render

    expect(view.content_for(:page_title)).to eql("Enter your code")
  end

  it "renders a text field with inputmode='numeric' and autocomplete='one-time-code'" do
    render

    expect(rendered).to have_css("form input[inputmode='numeric']")
  end

  it "renders a 'Sign in' button" do
    render

    expect(rendered).to have_css("form button", text: "Sign in")
  end
end
