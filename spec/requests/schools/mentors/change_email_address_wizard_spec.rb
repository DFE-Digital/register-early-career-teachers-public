describe "Schools::Mentors::ChangeEmailAddressWizardController", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher:,
      school:,
      email: "mentor@example.com"
    )
  end

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
    let(:params) { {edit: {email: new_email}} }

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

      context "when the email is valid" do
        let(:new_email) { "new-mentor@example.com" }

        it "updates the email only after confirmation" do
          expect { post(path_for_step("edit"), params:) }
            .not_to change(mentor_at_school_period, :email)

          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          expect { post path_for_step("check-answers") }
            .to change { mentor_at_school_period.reload.email }
            .to(new_email)

          expect(response).to redirect_to(path_for_step("confirmation"))
        end

        it "creates an event only after confirmation" do
          allow(Events::Record).to receive(:record_teacher_email_updated_event!)

          post(path_for_step("edit"), params:)

          expect(Events::Record).not_to have_received(:record_teacher_email_updated_event!)
          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          post path_for_step("check-answers")

          expect(Events::Record).to have_received(:record_teacher_email_updated_event!)
          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end

      context "when the email is unchanged" do
        it "returns unprocessable_content" do
          post(path_for_step("edit"), params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  private

  def path_for_step(step)
    "/school/mentors/#{mentor_at_school_period.id}/change-email-address/#{step}"
  end
end
