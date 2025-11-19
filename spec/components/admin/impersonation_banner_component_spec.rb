describe "Admin::ImpersonationBannerComponent", type: :component do
  let(:component) { Admin::ImpersonationBannerComponent.new(user:, school:) }

  let(:school) { FactoryBot.create(:school) }
  let(:dfe_staff_member) { FactoryBot.create(:user) }

  context "when the user is not impersonating" do
    let(:user) { FactoryBot.create(:school_user, school_urn: school.urn) }

    before { render_inline(component) }

    it "does not render" do
      expect(rendered_content).to be_empty
    end
  end

  context "when the user is impersonating" do
    let(:user) do
      FactoryBot.build(:dfe_user_impersonating_school_user, email: dfe_staff_member.email, school_urn: school.urn)
    end

    before { render_inline(component) }

    it "renders a sentence explaining that impersonation is happening" do
      expect(rendered_content).to have_content("You are signed in as #{school.name}")
    end

    it "renders a warning paragraph" do
      expect(rendered_content).to have_content(/Make any changes with care/)
    end

    it "renders a button to finish impersonating" do
      expect(rendered_content).to have_button("Sign out from #{school.name}")
    end
  end
end
