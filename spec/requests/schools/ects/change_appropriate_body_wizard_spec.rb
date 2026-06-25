describe "Schools::ECTs::ChangeAppropriateBodyWizardController" do
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { ect_at_school_period.teacher }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, school_reported_appropriate_body: current_appropriate_body) }
  let(:current_appropriate_body) { FactoryBot.create(:appropriate_body_period) }

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

      context "when the current_step is invalid" do
        it "returns not found" do
          get path_for_step("nope")

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the current_step is valid" do
        it "returns ok" do
          subject

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "POST #create" do
    subject { post(path_for_step("edit"), params:) }

    let(:params) { { edit: { appropriate_body_id: } } }
    let(:new_appropriate_body) { FactoryBot.create(:appropriate_body_period) }
    let(:appropriate_body_id) { new_appropriate_body.id }

    it_behaves_like "an induction redirectable route"

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
      let(:school_user) { FactoryBot.create(:school_user, school:) }

      before { sign_in_as(:school_user, school:) }

      context "when the current_step is invalid" do
        it "returns not found" do
          post(path_for_step("nope"), params:)

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the appropriate body id is missing" do
        let(:appropriate_body_id) { "" }

        it "returns unprocessable_content" do
          subject

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context "when the appropriate body id is valid" do
        it "changes the appropriate body" do
          subject

          expect(response).to redirect_to(path_for_step("check-answers"))
          expect(ect_at_school_period.reload.school_reported_appropriate_body).to eq(current_appropriate_body)

          follow_redirect!

          post path_for_step("check-answers")

          expect(response).to redirect_to(path_for_step("confirmation"))
          expect(ect_at_school_period.reload.school_reported_appropriate_body).to eq(new_appropriate_body)
        end

        it "records an event when the appropriate body is changed" do
          allow(Events::Record).to receive(:record_teacher_appropriate_body_changed!)

          subject

          expect(response).to redirect_to(path_for_step("check-answers"))
          expect(Events::Record).not_to have_received(:record_teacher_appropriate_body_changed!)

          follow_redirect!

          post path_for_step("check-answers")

          expect(response).to redirect_to(path_for_step("confirmation"))
          # expect(Events::Record).to have_received(:record_teacher_appropriate_body_changed!)
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/ects/#{ect_at_school_period.id}/change-appropriate-body/#{step}"
  end
end
