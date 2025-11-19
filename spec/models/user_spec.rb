describe User do
  subject(:user) { FactoryBot.build(:user) }

  describe "validation" do
    it { is_expected.to validate_presence_of(:email).with_message("Enter an email address") }
    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity.with_message("Email address already used, enter another") }
    it { is_expected.to validate_presence_of(:name).with_message("Enter a name") }
    it { is_expected.to validate_inclusion_of(:role).in_array(%i[admin finance super_admin]).with_message("Must be admin, finance or super_admin") }
    it { is_expected.to validate_presence_of(:role).with_message("Choose a role") }
  end

  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:authored_events).inverse_of(:author).class_name("Event") }
  end

  describe "enums" do
    it "has a roles enum with admin, finance and superuser" do
      expect(subject).to(
        define_enum_for(:role)
          .with_values({ admin: "admin",
                         super_admin: "super_admin",
                         finance: "finance" })
          .backed_by_column_of_type(:enum)
      )
    end
  end

  describe "scopes" do
    describe ".alphabetical" do
      it "orders by name ascending" do
        expect(User.alphabetical.to_sql).to end_with('ORDER BY "users"."name" ASC')
      end
    end
  end
end
