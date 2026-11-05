RSpec.describe "Admin::Teachers::ChangeTRNWizardController", type: :request do
  include_context "sign in as product_team DfE user"

  let(:user) { FactoryBot.create(:user, role: :user_manager) }

  let(:teacher) do
    FactoryBot.create(:teacher, :deactivated_in_trs, trn: "7654321")
  end

  let(:new_trn) { "2345678" }
  let(:entry_path) { admin_teacher_change_trn_wizard_enter_trn_path(teacher) }
  let(:confirm_path) { admin_teacher_change_trn_wizard_confirm_path(teacher) }
  let(:confirmation_path) do
    admin_teacher_change_trn_wizard_confirmation_path(teacher)
  end

  let(:api_client) { instance_double(TRS::APIClient) }
  let(:trs_teacher) do
    instance_double(
      TRS::Teacher,
      trs_first_name: "Sarah",
      trs_last_name: "Jones"
    )
  end

  before do
    allow(TRS::APIClient).to receive(:build).and_return(api_client)
    allow(api_client).to receive(:find_teacher)
      .with(trn: new_trn)
      .and_return(trs_teacher)
  end

  context "when signed in as an admin without the user manager role" do
    let(:user) { FactoryBot.create(:user, :admin) }

    it "blocks access to the entry page" do
      get entry_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "blocks a direct confirmation submission" do
      expect {
        post confirm_path, params: { confirm: { confirmed: "1", expected_trn: new_trn } }
      }.not_to(change { teacher.reload.trn })

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not show the change TRN link" do
      get admin_teacher_path(teacher)

      expect(response.body).not_to include(
        "Change the TRN for this deactivated record"
      )
    end

    it "blocks submitting a replacement TRN" do
      expect(api_client).not_to receive(:find_teacher)

      post entry_path, params: { enter_trn: { trn: new_trn } }

      expect(response).to have_http_status(:unauthorized)
      expect(teacher.reload.trn).to eq("7654321")
    end
  end

  %i[finance product_team].each do |role|
    context "when signed in as #{role}" do
      let(:user) { FactoryBot.create(:user, role:) }

      it "allows access to the entry page" do
        get entry_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the change TRN link" do
        get admin_teacher_path(teacher)

        expect(response.body).to include(entry_path)
      end
    end
  end

  describe "GET teacher overview" do
    it "shows the change TRN link for a deactivated teacher" do
      get admin_teacher_path(teacher)

      expect(response.body).to include(entry_path)
      expect(response.body).to include(
        "Change the TRN for this deactivated record"
      )
    end

    context "when the teacher is not deactivated" do
      let(:teacher) { FactoryBot.create(:teacher, trs_response: "ok") }

      it "does not show the change TRN link" do
        get admin_teacher_path(teacher)

        expect(response.body).not_to include(
          "Change the TRN for this deactivated record"
        )
      end
    end
  end

  describe "changing a TRN" do
    it "requires confirmation, replaces the TRN and records the admin author" do
      get entry_path

      expect(response).to have_http_status(:ok)

      post entry_path, params: { enter_trn: { trn: new_trn } }

      expect(response).to redirect_to(confirm_path)
      expect(teacher.reload.trn).to eq("7654321")

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("7654321", new_trn, "Sarah Jones")

      post confirm_path, params: { confirm: { confirmed: "0", expected_trn: new_trn } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "Confirm you want to change this teacher’s TRN"
      )
      expect(teacher.reload.trn).to eq("7654321")
      expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty

      expect {
        post confirm_path, params: { confirm: { confirmed: "1", expected_trn: new_trn } }
      }.to have_enqueued_job(Teachers::SyncTeacherWithTRSJob).with(teacher:)

      expect(response).to redirect_to(confirmation_path)
      expect(teacher.reload).to have_attributes(
        trn: new_trn,
        trs_response: "ok",
        trs_redirected_to: nil
      )

      event = teacher.events.where(event_type: "teacher_trn_replaced").sole

      expect(event).to have_attributes(
        author_id: user.id,
        author_type: "dfe_staff_user",
        metadata: {
          "old_trn" => "7654321",
          "new_trn" => new_trn
        }
      )

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "TRN changed for #{Teachers::Name.new(teacher).full_name}",
        "7654321",
        new_trn,
        "The old TRN has been deleted from the record.",
        "Back to teachers"
      )

      post confirm_path, params: { confirm: { confirmed: "1", expected_trn: new_trn } }

      expect(response).to redirect_to(confirmation_path)
      expect(teacher.events.where(event_type: "teacher_trn_replaced").count).to eq(1)
    end

    it "uses the corrected name in the heading and the TRS name in the summary" do
      teacher.update!(corrected_name: "Sarah Smith")

      post entry_path, params: { enter_trn: { trn: new_trn } }
      follow_redirect!

      expect(response).to have_http_status(:ok)

      document = Nokogiri::HTML(response.body)

      expect(document.at_css("h1").text).to include(
        "Confirm change of TRN for Sarah Smith"
      )

      trs_name_row = document.css(".govuk-summary-list__row").find do |row|
        row.at_css(".govuk-summary-list__key").text.strip == "Name from TRS"
      end

      expect(trs_name_row).to be_present
      expect(trs_name_row.at_css(".govuk-summary-list__value").text.strip)
        .to eq("Sarah Jones")
    end

    it "rejects confirmation when the proposed TRN has changed since review" do
      other_trn = "3456789"

      allow(api_client).to receive(:find_teacher)
        .with(trn: other_trn)
        .and_return(trs_teacher)

      # Tab A: enter and review the first replacement TRN
      post entry_path, params: { enter_trn: { trn: new_trn } }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(new_trn)

      # Tab B: enter a different replacement TRN in the same session
      post entry_path, params: { enter_trn: { trn: other_trn } }

      expect(response).to redirect_to(confirm_path)

      # Tab A: submit the confirmation for the originally reviewed TRN
      expect {
        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      }.not_to(change { teacher.reload.trn })

      expect(response).to redirect_to(confirm_path)
      expect(flash[:error]).to eq(
        "The proposed TRN has changed. Review the updated details before continuing."
      )
      expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
      expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
    end

    it "returns to TRN entry when the replacement TRN becomes occupied after review" do
      post entry_path, params: { enter_trn: { trn: new_trn } }
      FactoryBot.create(:teacher, trn: new_trn)

      expect {
        post confirm_path, params: { confirm: { confirmed: "1", expected_trn: new_trn } }
      }.not_to(change { teacher.reload.trn })

      expect(response).to redirect_to(entry_path)
      expect(flash[:error]).to eq(
        "The teacher records are not eligible for replacement with the supplied TRN. " \
        "This could be because another teacher redirects to the supplied TRN, " \
        "or because the supplied TRN is missing or unchanged."
      )
      expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued

      get confirm_path

      expect(response).to redirect_to(entry_path)
    end

    it "clears an earlier proposal when an invalid TRN is submitted" do
      post entry_path, params: { enter_trn: { trn: new_trn } }

      expect(response).to redirect_to(confirm_path)

      post entry_path, params: { enter_trn: { trn: "1234" } }

      expect(response).to have_http_status(:unprocessable_content)

      get confirm_path

      expect(response).to redirect_to(entry_path)

      expect {
        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      }.not_to(change { teacher.reload.trn })

      expect(response).to redirect_to(entry_path)
      expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
      expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
    end
  end

  describe "accessing confirmation without entering a TRN" do
    it "redirects GET requests to the entry page" do
      get confirm_path

      expect(response).to redirect_to(entry_path)
    end

    it "prevents direct POST requests from changing the teacher" do
      expect {
        post confirm_path, params: { confirm: { confirmed: "1", expected_trn: new_trn } }
      }.not_to(change { teacher.reload.trn })

      expect(response).to redirect_to(entry_path)
      expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
    end
  end

  context "when the teacher is not deactivated" do
    let(:teacher) { FactoryBot.create(:teacher, trs_response: "ok") }

    it "redirects back to the teacher overview with an explanation" do
      get entry_path

      expect(response).to redirect_to(admin_teacher_path(teacher))
      expect(flash[:error]).to eq(
        "This teacher record is no longer deactivated."
      )
    end
  end
end
