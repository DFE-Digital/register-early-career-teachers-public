describe "Admin::Teachers::ReopenInductionController" do
  let(:teacher) { FactoryBot.create(:teacher) }

  describe "GET confirm" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get confirm_admin_teacher_reopen_induction_path(teacher)

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "returns unauthorized" do
        get confirm_admin_teacher_reopen_induction_path(teacher)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a DfE user" do
      include_context "sign in as DfE user"

      context "when there is no last induction period" do
        it "redirects to the teacher page" do
          get confirm_admin_teacher_reopen_induction_path(teacher)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is ongoing" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, :ongoing, teacher:)
        end

        it "redirects to the teacher page" do
          get confirm_admin_teacher_reopen_induction_path(teacher)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is completed without an outcome" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, teacher:)
        end

        it "redirects to the teacher page" do
          get confirm_admin_teacher_reopen_induction_path(teacher)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is completed with an outcome" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, :pass, teacher:)
        end

        it "renders the confirm page" do
          get confirm_admin_teacher_reopen_induction_path(teacher)

          expect(response.body).to include("Are you sure you want to reopen this induction?")
        end
      end
    end
  end

  describe "PATCH update" do
    let(:params) do
      { admin_reopen_induction_period: { zendesk_ticket_id:, note: } }
    end
    let(:zendesk_ticket_id) { "1234" }
    let(:note) { "A test note" }

    context "when not signed in" do
      it "redirects to the sign in page" do
        patch admin_teacher_reopen_induction_path(teacher)

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "returns unauthorized" do
        patch admin_teacher_reopen_induction_path(teacher)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a DfE user" do
      include_context "sign in as DfE user"

      context "when there is no last induction period" do
        it "redirects to the teacher page without reopening the induction period" do
          patch(admin_teacher_reopen_induction_path(teacher), params:)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is ongoing" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, :ongoing, teacher:)
        end

        it "redirects to the teacher page without reopening the induction period" do
          expect { patch(admin_teacher_reopen_induction_path(teacher), params:) }
            .not_to(change { induction_period.reload.outcome })

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is completed without an outcome" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, teacher:)
        end

        it "redirects to the teacher page without reopening the induction period" do
          expect { patch(admin_teacher_reopen_induction_path(teacher), params:) }
            .not_to(change { induction_period.reload.outcome })

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is completed with an outcome" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, :pass, teacher:)
        end

        it "reopens the induction period and redirects to the teacher page" do
          expect { patch(admin_teacher_reopen_induction_path(teacher), params:) }
            .to change { induction_period.reload.outcome }
            .from("pass").to(nil)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end

        context "when no extra information is provided" do
          let(:note) { "" }
          let(:zendesk_ticket_id) { "" }

          it "returns unprocessable_content and displays an error without " \
             "reopening the induction period" do
            expect { patch(admin_teacher_reopen_induction_path(teacher), params:) }
              .not_to(change { induction_period.reload.outcome })

            expect(response).to have_http_status(:unprocessable_content)
            expect(response.body).to include("There is a problem")
          end
        end
      end
    end
  end
end
