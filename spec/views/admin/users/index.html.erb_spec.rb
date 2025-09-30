describe 'admin/users/index.html.erb' do
  let(:super_admin_user) { FactoryBot.create(:user, :super_admin, name: 'Super admin user') }
  let(:finance_user) { FactoryBot.create(:user, :finance, name: 'Finance user') }
  let(:admin_user) { FactoryBot.create(:user, :admin, name: 'Admin user') }
  let(:users) { [super_admin_user, finance_user, admin_user] }

  before do
    assign(:users, users)
    render
  end

  it "has heading of 'DfE staff'" do
    expect(view.content_for(:page_header)).to have_css('h1', text: 'DfE staff')
  end

  it 'displays a list of all DfE staff' do
    expect(rendered).to have_css('table.govuk-table > tbody > tr', count: 3)
  end

  it 'displays the user names as links to the profile pages' do
    aggregate_failures do
      expect(rendered).to have_link(super_admin_user.name, href: admin_user_path(super_admin_user))
      expect(rendered).to have_link(finance_user.name, href: admin_user_path(finance_user))
      expect(rendered).to have_link(admin_user.name, href: admin_user_path(admin_user))
    end
  end

  it 'displays the elevated roles but not regular admin' do
    expect(rendered).to have_css('td', text: 'Super admin')
    expect(rendered).to have_css('td', text: 'Finance')
    expect(rendered).to have_css('td', text: 'Admin')
  end
end
