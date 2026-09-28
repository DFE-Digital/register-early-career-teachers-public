describe "admin/users/index.html.erb" do
  let(:user_manager_user) { FactoryBot.create(:user, :user_manager, name: "User manager user") }
  let(:finance_user) { FactoryBot.create(:user, :finance, name: "Finance user") }
  let(:admin_user) { FactoryBot.create(:user, :admin, name: "Admin user") }
  let(:product_team_user) { FactoryBot.create(:user, :product_team, name: "Product team user", updated_at: 3.months.ago) }

  let(:users) { [user_manager_user, finance_user, product_team_user, admin_user] }

  before do
    assign(:users, users)
    render
  end

  it "has heading of 'DfE staff'" do
    expect(view.content_for(:page_header)).to have_css("h1", text: "DfE staff")
  end

  it "displays a list of all DfE staff" do
    expect(rendered).to have_css("table.govuk-table > tbody > tr", count: 4)
  end

  it "has columns for name, roles and last active on" do
    expect(rendered).to have_css("th", text: "Name")
    expect(rendered).to have_css("th", text: "Roles")
    expect(rendered).to have_css("th", text: "Last active on")
  end

  describe "last active dates" do
    it "displays the last active dates for recently-active users" do
      expect(rendered).to have_css("td", text: Date.current.to_formatted_s(:govuk), count: 3)
    end

    it "displays the last active date plus indicator since last active for inactive users" do
      date = 3.months.ago.to_date.to_formatted_s(:govuk)

      expect(rendered).to have_css("td", text: "#{date} (3 months ago)", count: 1)
    end
  end

  it "displays the user names as links to the profile pages" do
    aggregate_failures do
      expect(rendered).to have_link(user_manager_user.name, href: admin_user_path(user_manager_user))
      expect(rendered).to have_link(finance_user.name, href: admin_user_path(finance_user))
      expect(rendered).to have_link(product_team_user.name, href: admin_user_path(product_team_user))
      expect(rendered).to have_link(admin_user.name, href: admin_user_path(admin_user))
    end
  end

  it "displays the elevated roles but not regular admin" do
    expect(rendered).to have_css("td", text: "User manager")
    expect(rendered).to have_css("td", text: "Finance")
    expect(rendered).to have_css("td", text: "Product team")
    expect(rendered).to have_css("td", text: "Admin")
  end
end
