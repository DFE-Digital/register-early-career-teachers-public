RSpec.describe "appropriate_bodies/claim_an_ect/register_ect/show.html.erb" do
  let(:pending_induction_submission) { create(:pending_induction_submission, trs_first_name: 'Crispin', trs_last_name: 'Bonham-Carter') }

  it "sets the page title to '<name> is registered'" do
    assign(:appropriate_body, pending_induction_submission.appropriate_body)
    assign(:pending_induction_submission, pending_induction_submission)

    render

    expected_title = "Crispin Bonham-Carter is registered"
    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(expected_title))
  end

  it 'has links to register another ECT and to return to the homepage' do
    assign(:appropriate_body, pending_induction_submission.appropriate_body)
    assign(:pending_induction_submission, pending_induction_submission)

    render

    expect(rendered).to have_link('Back to homepage', href: '/appropriate-body/teachers')
    expect(rendered).to have_link('Claim another ECT', href: '/appropriate-body/claim-an-ect/find-ect/new')
  end
end
