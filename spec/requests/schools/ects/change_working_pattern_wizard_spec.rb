describe "Schools::ECTs::ChangeWorkingPatternWizardController", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher:,
      school:,
      working_pattern: "full_time"
    )
  end

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

    let(:params) { { edit: { working_pattern: new_working_pattern } } }
    let(:new_working_pattern) { "part_time" }

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
        subject

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

      context "when the working pattern is valid" do
        let(:new_working_pattern) { "part_time" }

        it "updates the working pattern only after confirmation" do
          expect { subject }
            .not_to change(ect_at_school_period, :working_pattern)

          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          expect { post path_for_step("check-answers") }
            .to change { ect_at_school_period.reload.working_pattern }
            .to(new_working_pattern)

          expect(response).to redirect_to(path_for_step("confirmation"))
        end

        it "creates an event only after confirmation" do
          allow(Events::Record).to receive(:record_teacher_working_pattern_updated_event!)

          subject

          expect(Events::Record).not_to have_received(:record_teacher_working_pattern_updated_event!)
          expect(response).to redirect_to(path_for_step("check-answers"))

          follow_redirect!

          post path_for_step("check-answers")

          expect(Events::Record).to have_received(:record_teacher_working_pattern_updated_event!)
          expect(response).to redirect_to(path_for_step("confirmation"))
        end
      end

      context "when the working pattern is unchanged" do
        let(:new_working_pattern) { "full_time" }

        it "returns unprocessable_content" do
          subject

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

private

  def path_for_step(step)
    "/school/ects/#{ect_at_school_period.id}/change-working-pattern/#{step}"
  end
end
