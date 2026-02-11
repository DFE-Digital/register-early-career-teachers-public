RSpec.describe Current, type: :model do
  let(:current_user) { FactoryBot.create(:dfe_user, name: "Admin user", role: "admin") }

  it "has a version number" do
    expect(described_class).to respond_to(:user)
    expect(Current.user).to be_nil
    expect(described_class).to respond_to(:administrator)
    expect(Current.administrator).to be_nil
    expect(described_class).to respond_to(:role)
    expect(Current.role).to be_nil
    expect(described_class).to respond_to(:session)
    expect(Current.session).to eq({})
  end

  describe "user" do
    it "can be assigned and retrieved" do
      Current.user = current_user
      expect(Current.user).to eq(current_user)
    end
  end

  describe "administrator" do
    it "is derived from user and can be retrieved" do
      Current.user = current_user
      expect(Current.administrator).to eq(current_user.user)
      expect(Current.administrator.name).to eq("Admin user")
    end
  end

  describe "role" do
    it "is derived from user and can be retrieved" do
      Current.user = current_user
      expect(Current.role).to eq("Admin")
    end
  end

  describe "session" do
    it "can be assigned and retrieved" do
      current_session = { token: "abc123" }
      Current.session = current_session
      expect(Current.session).to eq(current_session)
    end
  end
end
