describe 'admin/users/new.html.erb' do
  let(:role) { :admin }
  let(:user) { User.new }

  before do
    assign(:user, user)
    render
  end

  it 'shows add a new DfE staff member in the header' do
    expect(view.content_for(:page_header)).to have_css('h1', text: "Add a new DfE staff member")
  end

  it 'includes a back link to admin users list' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: admin_users_path)
  end

  it 'contains a form that targets the users path' do
    expect(rendered).to have_css(%(form[action='#{admin_users_path}']))
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
    expect(rendered).to have_css('button', text: 'Add user')
  end
end
