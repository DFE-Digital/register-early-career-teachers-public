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

  describe "#admin_teacher_navigation_items" do
    let(:teacher) { FactoryBot.build_stubbed(:teacher) }

    it "marks the matching tab as current" do
      items = admin_teacher_navigation_items(teacher, :induction)
      induction = items.find { |item| item[:text] == "Induction" }
      timeline = items.find { |item| item[:text] == "Timeline" }

      expect(induction[:current]).to be(true)
      expect(timeline[:current]).to be(false)
    end

    it "includes the timeline link" do
      items = admin_teacher_navigation_items(teacher, :timeline)
      timeline = items.find { |item| item[:text] == "Timeline" }

      expect(timeline[:href]).to eq(admin_teacher_timeline_path(teacher))
      expect(timeline[:current]).to be(true)
    end
  end
end
