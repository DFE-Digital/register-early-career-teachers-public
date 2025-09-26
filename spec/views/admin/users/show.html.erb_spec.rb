describe 'admin/users/show.html.erb' do
  let(:role) { :admin }
  let(:user) { FactoryBot.create(:user, role) }

  before do
    assign(:user, user)
    render
  end

  it 'includes a back link to admin users list' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: admin_users_path)
  end

  it 'shows the name in the h1' do
    expect(view.content_for(:page_header)).to have_css('h1', text: user.name)
  end

  it 'displays the full name' do
    expect(rendered).to have_css('dt', text: 'Name')
    expect(rendered).to have_css('dd', text: user.name)
  end

  it 'displays the email address' do
    expect(rendered).to have_css('dt', text: 'Email address')
    expect(rendered).to have_css('dd', text: user.email)
  end

  it 'displays the creation date' do
    expect(rendered).to have_css('dt', text: 'Created on')
    expect(rendered).to have_css('dd', text: user.created_at.to_date.to_fs(:govuk))
  end

  it 'displays the role (admin by default)' do
    expect(rendered).to have_css('dt', text: 'Role')
    expect(rendered).to have_css('dd', text: 'Admin')
  end

  context 'when the user is a super admin user' do
    let(:role) { :super_admin }

    it 'displays the finance role' do
      expect(rendered).to have_css('dt', text: 'Role')
      expect(rendered).to have_css('dd', text: 'Super admin')
    end
  end

  context 'when the user is a finance user' do
    let(:role) { :finance }

    it 'displays the finance role' do
      expect(rendered).to have_css('dt', text: 'Role')
      expect(rendered).to have_css('dd', text: 'Finance')
    end
  end
end
