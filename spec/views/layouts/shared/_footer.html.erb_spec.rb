RSpec.describe "layouts/shared/_footer.html.erb" do
  subject { rendered }

  describe "support link" do
    let(:current_user) { nil }
    let(:normal_href) { "/support" }
    let(:schools_href) { new_schools_support_query_path }

    before do
      without_partial_double_verification do
        allow(view).to receive(:current_user).and_return(current_user)
      end
      render
    end

    shared_examples "normal support link" do
      it { is_expected.to have_link("Contact support", href: normal_href) }
      it { is_expected.not_to have_link("Contact support", href: schools_href) }
    end

    context "when not signed in" do
      include_examples "normal support link"
    end

    context "when signed in as non-school user" do
      let(:current_user) { FactoryBot.create(:appropriate_body_user, :at_random_appropriate_body) }

      include_examples "normal support link"
    end

    context "when signed in as school user" do
      let(:current_user) { FactoryBot.create(:school_user, :at_random_school) }

      it { is_expected.not_to have_link("Contact support", href: normal_href) }
      it { is_expected.to have_link("Contact support", href: schools_href) }
    end
  end
end
