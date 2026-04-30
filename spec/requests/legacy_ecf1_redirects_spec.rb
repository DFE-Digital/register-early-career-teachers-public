# These redirects handle old ECF1 service URLs that may still appear in search
# engine results and send users to the new service root page.
RSpec.describe "Legacy ECF1 redirects", type: :request do
  %w[
    /users/sign_in
    /check-account
    /nominations/resend-email
  ].each do |path|
    describe "GET #{path}" do
      it "redirects to the root path" do
        get path

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
