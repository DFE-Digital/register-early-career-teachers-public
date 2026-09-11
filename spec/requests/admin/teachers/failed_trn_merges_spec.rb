RSpec.describe "Teachers::FailedTRNMerges", type: :request do
  describe "GET /admin/teachers/failed_trn_merges" do
    subject { get admin_failed_trn_merges_path }

    it "redirects to sign in path when not authenticated" do
      subject

      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      it "returns a successful response" do
        subject

        expect(response).to have_http_status(:ok)
      end

      context "when there are failed TRN merges" do
        let!(:teacher_1) { FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: redirected_teacher_1.trn) }
        let(:redirected_teacher_1) { FactoryBot.create(:teacher) }
        let!(:teacher_2) { FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: redirected_teacher_2.trn) }
        let(:redirected_teacher_2) { FactoryBot.create(:teacher) }
        let!(:unredirected_teacher) { FactoryBot.create(:teacher) }

        it "lists the failed TRN merges" do
          subject

          page = Capybara.string(response.body)

          expect(page).to have_link(teacher_1.trn, href: admin_teacher_path(teacher_1))
          expect(page).to have_link(teacher_2.trn, href: admin_teacher_path(teacher_2))
          expect(page).to have_link(redirected_teacher_1.trn, href: admin_teacher_path(redirected_teacher_1))
          expect(page).to have_link(redirected_teacher_2.trn, href: admin_teacher_path(redirected_teacher_2))
          expect(page).not_to have_link(unredirected_teacher.trn, href: admin_teacher_path(unredirected_teacher))
        end

        context "when the redirected teacher does not exist in the system" do
          let!(:teacher_1) { FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: "0123456") }

          it "lists the failed TRN merge with a non-existent redirected teacher" do
            subject

            page = Capybara.string(response.body)

            expect(page).to have_link(teacher_1.trn, href: admin_teacher_path(teacher_1))
            expect(page).to have_content("0123456")
            expect(page).not_to have_link("0123456")
          end
        end
      end
    end
  end
end
