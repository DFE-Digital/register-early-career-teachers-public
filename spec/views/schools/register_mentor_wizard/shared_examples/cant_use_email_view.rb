RSpec.shared_examples "a can't use email step view" do |current_step:, back_path:|
  let(:mentor) { wizard.mentor }
  let(:email) { nil }
  let(:wizard) { build(:register_mentor_wizard, current_step:, store:) }
  let(:store) do
    build(:session_repository,
          trn: "1234567",
          trs_first_name: "John",
          trs_last_name: "Waters",
          trs_date_of_birth: "1950-01-01",
          change_name: "no",
          email: 'a@email.com')
  end

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    render
  end

  context 'page title' do
    it { expect(sanitize(view.content_for(:page_title))).to eql('This email is already in use for a different ECT or mentor') }
  end

  it 'includes a back button that links to the previous page' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: send(back_path))
  end

  it 'includes a try another email button that links to the previous page' do
    expect(rendered).to have_link('Try another email', href: send(back_path))
  end
end
