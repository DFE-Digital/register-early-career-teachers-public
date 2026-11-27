describe "Schools::Mentors::ChangeNameWizardController" do
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Miriam", trs_last_name: "Margolyes") }
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:, school:)
  end
  let(:mentor_at_school_period_id) { mentor_at_school_period.id }

  describe "GET #new" do
    subject { get path_for_step("edit") }

    it_behaves_like "an induction redirectable route"

    context "when not signed in" do
      it "redirects to the root page" do
        subject

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-School user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a School user" do
      before { sign_in_as(:school_user, school:) }

      context "when the current step is invalid" do
        it "returns not found" do
          get path_for_step("nope")

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the current step is valid" do
        it "returns ok and prefills the existing name" do
          subject

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('value="Miriam Margolyes"')
        end

        it "resets the saved name when starting a new journey" do
          post path_for_step("edit"), params: { edit: { name: "Miriam Sprout" } }
          follow_redirect!
          expect(response).to have_http_status(:ok)

          get path_for_step("edit"), headers: { "HTTP_REFERER" => root_url }
          expect(response).to have_http_status(:ok)

          get path_for_step("check-answers")

          expect(response).to redirect_to(path_for_step("edit"))
        end

        it "retains the saved name when returning within the wizard" do
          post path_for_step("edit"), params: { edit: { name: "Miriam Sprout" } }
          follow_redirect!
          expect(response).to have_http_status(:ok)

          get path_for_step("edit"), headers: { "HTTP_REFERER" => path_for_step("check-answers") }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('value="Miriam Sprout"')

          get path_for_step("check-answers")

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Miriam Sprout")
        end
      end

      context "when check answers is accessed without a valid edit step" do
        it "redirects to the edit step" do
          get path_for_step("check-answers")

          expect(response).to redirect_to(path_for_step("edit"))
        end
      end
    end
  end

  describe "POST #create" do
    subject { post(path_for_step("edit"), params:) }

    let(:params) { { edit: { name: new_name } } }
    let(:new_name) { "Miriam Margolyes" }

    it_behaves_like "an induction redirectable route"

    context "when not signed in" do
      it "redirects to the root page" do
        subject

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-School user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a School user" do
      before { sign_in_as(:school_user, school:) }

      context "when the current step is invalid" do
        it "returns not found" do
          post(path_for_step("nope"), params:)

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the name is valid" do
        let(:new_name) { "Miriam Sprout" }

        it "updates the name only after confirmation" do
          expect { subject }
            .not_to(change { teacher.reload.corrected_name })

          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          expect { post path_for_step("check-answers") }
            .to change { teacher.reload.corrected_name }
            .to(new_name)

          expect(response).to redirect_to(path_for_step("confirmation"))

          follow_redirect!

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("You’ve changed the mentor’s name to #{new_name}")
        end

        it "creates an event only after confirmation" do
          subject

          expect(Event.where(event_type: "teacher_name_updated_by_user")).to be_empty
          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          post path_for_step("check-answers")

          expect(Event.where(event_type: "teacher_name_updated_by_user")).to be_present
          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end

      context "when the name change is significant" do
        let(:new_name) { "Sister Mildred" }

        it "routes through the name-change confirmation step" do
          subject

          expect(response).to redirect_to(path_for_step("confirm-name-change"))

          follow_redirect!

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Cancel and return to Miriam Margolyes’s details")
          expect(response.body).to include("href=\"/school/mentors/#{mentor_at_school_period.id}\"")
        end
      end

      context "when the name is unchanged" do
        it "returns unprocessable content" do
          subject

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/mentors/#{mentor_at_school_period.id}/change-name/#{step}"
  end
end
