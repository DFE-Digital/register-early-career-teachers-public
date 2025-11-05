RSpec.describe "Admin recording a failed outcome for a teacher" do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let!(:induction_period) do
    FactoryBot.create(:induction_period, :ongoing,
                      teacher:,
                      appropriate_body_period:)
  end

  describe "GET /admin/teachers/:teacher_id/record-failed-outcome/new" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get("/admin/teachers/#{teacher.id}/record-failed-outcome/new")

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as an admin" do
      include_context "sign in as DfE user"

      it "renders" do
        get("/admin/teachers/#{teacher.id}/record-failed-outcome/new")

        expect(response).to be_successful
        expect(response.body).to include("Record failed outcome")
      end

      it "returns not found for an invalid teacher" do
        get("/admin/teachers/invalid-trn/record-failed-outcome/new")

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /admin/teachers/:teacher_id/record-failed-outcome" do
    let(:params) do
      {
        admin_record_fail: {
          finished_on: Date.current,
          number_of_terms: 3,
          note: "Note from Admin",
          zendesk_ticket_id: "#123456"
        }
      }
    end

    context "when not signed in" do
      it "redirects to the root page" do
        post("/admin/teachers/#{teacher.id}/record-failed-outcome", params:)

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in as an admin" do
      include_context "sign in as DfE user"

      before do
        post("/admin/teachers/#{teacher.id}/record-failed-outcome", params:)
      end

      context "with valid params" do
        it "fails the induction and redirects" do
          expect(induction_period.reload).to have_attributes(
            outcome: "fail",
            finished_on: Date.current,
            number_of_terms: 3
          )

          expect(response).to redirect_to("/admin/teachers/#{teacher.id}/record-failed-outcome")
        end
      end

      context "with missing params" do
        let(:params) do
          {
            admin_record_fail: {
              finished_on: nil,
              number_of_terms: nil,
              note: nil,
              zendesk_ticket_id: nil
            }
          }
        end

        it "renders errors" do
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Enter a finish date")
          expect(response.body).to include("Enter a number of terms")
          expect(response.body).to include("Add a note or enter the Zendesk ticket number")
        end
      end

      context "invalid induction params" do
        let(:params) do
          {
            admin_record_fail: {
              finished_on: induction_period.started_on - 1.month,
              number_of_terms: 16.99,
              note: "Reason",
              zendesk_ticket_id: nil
            }
          }
        end

        it "renders errors" do
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("The end date must be later than the start date")
          expect(response.body).to include("Number of terms must be between 0 and 16")
        end
      end

      context "invalid auditable params" do
        let(:params) do
          {
            admin_record_fail: {
              finished_on: nil,
              number_of_terms: nil,
              note: nil,
              zendesk_ticket_id: "1234567"
            }
          }
        end

        it "renders errors" do
          expect(response.body).to include("There is a problem")
          expect(response.body).to include("Ticket number must be 6 digits")
        end
      end
    end
  end
end
