describe "Schools::Induction::ConfirmExistingInductionTutorWizardController", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }

  describe "GET #new" do
    context "when not signed in" do
      it "redirects to the root page" do
        get path_for_step("edit")

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-School user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        get path_for_step("edit")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a School user" do
      before { sign_in_as(:school_user, school:) }

      context "when the current_step is invalid" do
        it "returns not found" do
          get path_for_step("nope")

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the current_step is valid" do
        it "returns ok" do
          get path_for_step("edit")

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "POST #create" do
    let(:new_email) { "mentor@example.com" }
    let(:params) { { edit: { email: new_email } } }

    context "when not signed in" do
      it "redirects to the root path" do
        post(path_for_step("edit"), params:)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-School user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        post(path_for_step("edit"), params:)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a School user" do
      before { sign_in_as(:school_user, school:) }

      context "when the current_step is invalid" do
        it "returns not found" do
          post(path_for_step("nope"), params:)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the current details are confirmed' do
        it "does not update anything" do
          expect { post(path_for_step("edit"), params:) }
            .not_to change(school, :induction_tutor_email)

          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/induction/confirm-existing-induction-tutor/#{step}"
  end
end
