RSpec.shared_examples "requires finance access" do
  context "when not signed in" do
    it { is_expected.to redirect_to sign_in_path }
  end

  context "with an authenticated non-DfE user" do
    include_context "sign in as non-DfE user"

    it { is_expected.to have_http_status :unauthorized }
  end

  context "when signed in as a non-finance DfE user" do
    include_context "sign in as DfE user"

    it { is_expected.to have_http_status :unauthorized }

    it "renders the finance access error message" do
      expect(subject.body).to include(
        "This is to access financial information for Register early career teachers. To gain access, contact the product team."
      )
    end
  end
end
