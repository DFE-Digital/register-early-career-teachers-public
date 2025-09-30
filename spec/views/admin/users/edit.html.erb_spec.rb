describe 'admin/users/edit.html.erb' do
  let(:role) { :admin }
  let(:user) { FactoryBot.create(:user) }

  before do
    assign(:user, user)
    render
  end

  it 'shows the name in the h1' do
    expect(view.content_for(:page_header)).to have_css('h1', text: "Edit #{user.name}")
  end

  it 'includes a back link to admin users list' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: admin_users_path)
  end

  it 'contains a form that targets the user path' do
    expect(rendered).to have_css(%(form[action='#{admin_user_path(user)}']))
  end

  it 'displays a form with name, email and role fields' do
    expect(rendered).to have_css('label', text: 'Name')
    expect(rendered).to have_css('label', text: 'Email address')
    expect(rendered).to have_css('legend', text: 'Role')
  end

  it 'lists the roles as options' do
    expect(rendered).to have_css('label.govuk-radios__label', text: 'Admin')
    expect(rendered).to have_css('label.govuk-radios__label', text: 'Super admin')
    expect(rendered).to have_css('label.govuk-radios__label', text: 'Finance')
  end

  it 'has an add user button' do
    expect(rendered).to have_css('button', text: 'Update user')
  end

  context 'when the user has errors' do
    let(:user) do
      FactoryBot.create(:user) do |u|
        u.email = ''
        u.valid?
      end
    end

    it 'prefixes the page title with error' do
      expect(view.content_for(:page_title)).to start_with('Error:')
    end
  end
end
