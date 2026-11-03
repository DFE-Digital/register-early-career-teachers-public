describe "Admin::ImpersonationBannerComponent", type: :component do
  let(:component) { Admin::ImpersonationBannerComponent.new(user:) }

  before { render_inline(component) }

  context "when the organisation is a school" do
    let(:organisation) { FactoryBot.create(:school) }

    context "when the user is not impersonating" do
      let(:user) do
        FactoryBot.build_stubbed(:school_user, school_urn: organisation.urn)
      end

      it "does not render" do
        expect(rendered_content).to be_empty
      end
    end

    context "when the user is impersonating" do
      let(:dfe_staff_member) { FactoryBot.create(:user) }
      let(:user) do
        FactoryBot.build_stubbed(
          :dfe_user_impersonating_school_user,
          email: dfe_staff_member.email,
          school_urn: organisation.urn
        )
      end

      it "renders a sentence explaining that impersonation is happening" do
        expect(rendered_content).to have_content("You are signed in as #{organisation.name}")
      end

      it "renders a warning paragraph" do
        expect(rendered_content).to have_content(/Make any changes with care/)
      end

      it "renders a button to finish impersonating" do
        expect(rendered_content).to have_button("Sign out from #{organisation.name}")
      end
    end
  end

  context "when the organisation is an appropriate body" do
    let(:organisation) { FactoryBot.create(:appropriate_body_period) }

    context "when the user is not impersonating" do
      let(:user) do
        FactoryBot.build_stubbed(
          :appropriate_body_user,
          dfe_sign_in_organisation_id: organisation.dfe_sign_in_organisation_id
        )
      end

      it "does not render" do
        expect(rendered_content).to be_empty
      end
    end

    context "when the user is impersonating" do
      let(:dfe_staff_member) { FactoryBot.create(:user) }
      let(:user) do
        FactoryBot.build_stubbed(
          :dfe_user_impersonating_appropriate_body_user,
          email: dfe_staff_member.email,
          appropriate_body_period_id: organisation.id
        )
      end

      it "renders a sentence explaining that impersonation is happening" do
        expect(rendered_content).to have_content("You are signed in as #{organisation.name}")
      end

      it "renders a warning paragraph" do
        expect(rendered_content).to have_content(/Make any changes with care/)
      end

      it "renders a button to finish impersonating" do
        expect(rendered_content).to have_button("Sign out from #{organisation.name}")
      end
    end
  end
end
