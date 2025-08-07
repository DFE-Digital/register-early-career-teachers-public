describe "Admin::Teachers::ReopenInductionController" do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:reopen_service) { instance_double(Admin::ReopenInductionPeriod) }

  before do
    allow(Admin::ReopenInductionPeriod)
      .to receive(:new)
      .and_return(reopen_service)
  end

  describe "PATCH update" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        patch admin_teacher_reopen_induction_path(teacher)

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "redirects to the sign in page" do
        patch admin_teacher_reopen_induction_path(teacher)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a DfE user" do
      include_context "sign in as DfE user"

      context "when there is no last induction period" do
        it "redirects to the teacher page without reopening the induction period" do
          expect(reopen_service).not_to receive(:reopen_induction_period!)

          patch admin_teacher_reopen_induction_path(teacher)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is ongoing" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, :ongoing, teacher:)
        end

        it "redirects to the teacher page without reopening the induction period" do
          expect(reopen_service).not_to receive(:reopen_induction_period!)

          patch admin_teacher_reopen_induction_path(teacher)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is completed without an outcome" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, teacher:)
        end

        it "redirects to the teacher page without reopening the induction period" do
          expect(reopen_service).not_to receive(:reopen_induction_period!)

          patch admin_teacher_reopen_induction_path(teacher)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end

      context "when the last induction period is completed with an outcome" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, :pass, teacher:)
        end

        it "reopens the induction period and redirects to the teacher page" do
          expect(reopen_service).to receive(:reopen_induction_period!)

          patch admin_teacher_reopen_induction_path(teacher)

          expect(response).to redirect_to(admin_teacher_path(teacher))
        end
      end
    end
  end
end
