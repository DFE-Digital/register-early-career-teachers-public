describe "Schools::NewInductionTutorWizardController", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }
  let(:params) { {} }
  let(:induction_tutor_name) { "Old Induction Tutor Name" }
  let(:induction_tutor_email) { "old.name@gmail.com" }

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

    context "when visiting an invalid step" do
      it "renders a 404 page" do
        get path_for_step("fake-step")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
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

      context "when the details are valid" do
        let(:params) { { edit: { induction_tutor_name: "New Name", induction_tutor_email: "new.name@gmail.com" } } }

        it "updates the details" do
          FactoryBot.create(:contract_period, :current)

          expect { post(path_for_step("edit"), params:) }
            .not_to change(school, :induction_tutor_email)

          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          expect { post path_for_step("check-answers") }
            .to change { school.reload.induction_tutor_email }
            .to("new.name@gmail.com")
            .and change { school.reload.induction_tutor_name }
            .to("New Name")
            .and(change { school.reload.induction_tutor_last_nominated_in })

          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end
    end

    context "when visiting an invalid step" do
      it "renders a 404 page" do
        post path_for_step("fake-step")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

private

  def path_for_step(step)
    "/school/new-induction-tutor/#{step}"
  end
end
