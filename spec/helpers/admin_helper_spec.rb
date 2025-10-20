describe AdminHelper do
  describe "#role_name" do
    it "returns a human readable name given the database value" do
      aggregate_failures do
        expect(role_name(:admin)).to eql("Admin")
        expect(role_name(:super_admin)).to eql("Super admin")
        expect(role_name(:finance)).to eql("Finance")
      end
    end
  end

  describe "#role_options" do
    it "returns the roles as objects for use in radio collection" do
      expect(role_options.map(&:identifier)).to match_array(%i[admin finance super_admin])
    end
  end
end
