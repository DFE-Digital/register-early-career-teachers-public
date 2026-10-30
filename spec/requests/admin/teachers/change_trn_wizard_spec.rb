RSpec.describe "Admin::Teachers::ChangeTRNWizardController", type: :request do
  include_context "sign in as product_team DfE user"

  let(:user) { FactoryBot.create(:user, role: :user_manager) }

  let(:teacher) do
    FactoryBot.create(:teacher, :deactivated_in_trs, trn: "7654321")
  end

  let(:new_trn) { "2345678" }
  let(:entry_path) { admin_teacher_change_trn_wizard_enter_trn_path(teacher) }
  let(:confirm_path) { admin_teacher_change_trn_wizard_confirm_path(teacher) }

  let(:cannot_use_trn_path) do
    admin_teacher_change_trn_wizard_cannot_use_trn_path(teacher)
  end

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

  shared_examples "confirming a TRN change" do
    before do
      post entry_path, params: { enter_trn: { trn: new_trn } }
      post preview_path if merging
    end

    it "shows the appropriate confirmation form at the shared route" do
      get confirm_path

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      expect(document.at_css("form")["action"]).to eq(confirm_path)
      expect(document.at_css('input[name="confirm[expected_trn]"]')["value"]).to eq(new_trn)
      expect(response.body).to include(confirmation_message)
    end

    it "requires confirmation before updating either record" do
      post confirm_path, params: { confirm: { confirmed: "0", expected_trn: new_trn } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(confirmation_message)
      expect(teacher.reload.trn).to eq("7654321")
      expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
    end
  end

  shared_examples "does not merge the teacher records" do
    it "leaves the teacher records unchanged without recording or scheduling a merge" do
      expect(teacher.reload.trn).to eq("7654321")
      expect(destination.reload.trn).to eq(expected_destination_trn)
      expect(destination.events.where(event_type: "teacher_merged")).to be_empty
      expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
    end
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

    it "blocks submitting a replacement TRN" do
      expect(api_client).not_to receive(:find_teacher)

      post entry_path, params: { enter_trn: { trn: new_trn } }

      expect(response).to have_http_status(:unauthorized)
      expect(teacher.reload.trn).to eq("7654321")
    end

    it "prevents an unauthorised user from changing a teacher’s TRN" do
      expect {
        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      }.not_to(change { teacher.reload.trn })

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not show the change TRN link" do
      get admin_teacher_path(teacher)

      expect(response.body).not_to include(
        "Change the TRN for this deactivated record"
      )
    end

    it "prevents an unauthorised user from merging teacher records" do
      destination = FactoryBot.create(
        :teacher,
        trn: new_trn,
        trs_response: "ok"
      )
      source_id = teacher.id

      post admin_teacher_change_trn_wizard_confirm_path(teacher),
           params: {
             confirm: {
               confirmed: "1",
               expected_trn: new_trn
             }
           }

      expect(response).to have_http_status(:unauthorized)
      expect(Teacher.exists?(source_id)).to be(true)
      expect(destination.reload.trn).to eq(new_trn)
      expect(destination.events.where(event_type: "teacher_merged")).to be_empty
      expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
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

      expect(response.body).to include(
        entry_path,
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
    let(:merging) { false }
    let(:confirmation_message) { "I confirm I want to change this teacher’s TRN" }

    it_behaves_like "confirming a TRN change"

    it "requires confirmation, replaces the TRN and records the admin author" do
      get entry_path

      expect(response).to have_http_status(:ok)

      post entry_path, params: { enter_trn: { trn: new_trn } }

      expect(response).to redirect_to(confirm_path)
      expect(teacher.reload.trn).to eq("7654321")

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("7654321", new_trn, "Sarah Jones")

      expect {
        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
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

      post confirm_path,
           params: {
             confirm: {
               confirmed: "1",
               expected_trn: new_trn
             }
           }

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

      post entry_path, params: { enter_trn: { trn: new_trn } }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(new_trn)

      post entry_path, params: { enter_trn: { trn: other_trn } }

      expect(response).to redirect_to(confirm_path)

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

  describe "previewing a merge" do
    let(:merging) { true }
    let(:confirmation_message) { "I confirm I want to merge these teacher records" }

    let(:confirmation_path) do
      admin_teacher_change_trn_wizard_confirmation_path(teacher.id)
    end

    let(:preview_path) do
      admin_teacher_change_trn_wizard_merge_preview_path(teacher.id)
    end

    let(:expected_destination_trn) { new_trn }

    let!(:destination) do
      FactoryBot.create(
        :teacher,
        trn: new_trn,
        trs_response: "ok",
        trs_first_name: "Sarah",
        trs_last_name: "Jones"
      )
    end

    it_behaves_like "confirming a TRN change"

    context "when the records cannot be merged" do
      before do
        FactoryBot.create(:induction_period, teacher:)
        FactoryBot.create(:induction_period, teacher: destination)

        post entry_path, params: { enter_trn: { trn: new_trn } }
      end

      it "shows the cannot use TRN page" do
        expect(response).to redirect_to(cannot_use_trn_path)

        follow_redirect!

        expect(response).to have_http_status(:ok)
      end

      it_behaves_like "does not merge the teacher records"
    end

    it "shows both records without changing either teacher" do
      post entry_path, params: { enter_trn: { trn: new_trn } }

      expect(response).to redirect_to(preview_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Check teacher records before merging",
        teacher.trn,
        destination.trn,
        Teachers::Name.new(teacher).full_name,
        Teachers::Name.new(destination).full_name
      )

      expect(teacher.reload.trn).to eq("7654321")
      expect(destination.reload.trn).to eq(new_trn)
      expect(destination.events.where(event_type: "teacher_merged")).to be_empty
    end

    context "when previewing teacher history" do
      let(:document) { Nokogiri::HTML(response.body) }
      let(:columns) { document.css(".govuk-grid-column-one-half") }

      shared_examples "a teacher history column" do
        before do
          FactoryBot.create(:declaration, :"with_#{role}", teacher: record, started_on: Date.new(2025, 9, 1))
          post entry_path, params: { enter_trn: { trn: new_trn } }
          follow_redirect!
        end

        it "is on a page with two columns, shown before the teachers are updated" do
          expect(response).to have_http_status(:ok)
          expect(columns.size).to eq(2)
          expect(teacher.reload.trn).to eq("7654321")
          expect(destination.reload.trn).to eq(new_trn)
        end

        it "shows the teacher’s name, TRN, school periods, training periods and non-voided declarations" do
          expect(column.text).to include(record.trn)
          expect(column.text).to include(Teachers::Name.new(record).full_name)

          if record == teacher
            expect(column.text).to include("School periods that will merge", "Training periods that will merge")
          end

          if record == destination
            expect(column.text).to include("Existing school periods", "Existing training periods")
          end

          record.public_send("#{role}_at_school_periods").each do |period|
            expect(column.text).to include(period.school.name)
          end

          record.public_send("#{role}_training_periods").each do |period|
            expect(column.text).to include(period.lead_provider_name)
          end

          record.public_send("#{role}_declarations").each do |declaration|
            expect(column.text).to include(declaration.api_id)
            expect(declaration.training_period.teacher_id).to eq(record.id)
          end

          expect(document.css("a").map { |link| link.text.strip }).not_to include("Void declaration", "Move to a different partnership")
        end
      end

      context "when the source has ECT periods" do
        let(:record) { teacher }
        let(:column) { columns.first }
        let(:role) { :ect }

        it_behaves_like "a teacher history column"
      end

      context "when the destination has ECT periods" do
        let(:record) { destination }
        let(:column) { columns.last }
        let(:role) { :ect }

        it_behaves_like "a teacher history column"
      end

      context "when the source has mentor periods" do
        let(:record) { teacher }
        let(:column) { columns.first }
        let(:role) { :mentor }

        it_behaves_like "a teacher history column"
      end

      context "when the destination has mentor periods" do
        let(:record) { destination }
        let(:column) { columns.last }
        let(:role) { :mentor }

        it_behaves_like "a teacher history column"
      end
    end

    it "merges the records and shows success after deleting the source" do
      source_id = teacher.id
      source_trn = teacher.trn

      post entry_path, params: { enter_trn: { trn: new_trn } }
      post preview_path

      expect(response).to redirect_to(confirm_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Confirm merge for",
        source_trn,
        new_trn
      )

      post confirm_path,
           params: {
             confirm: {
               confirmed: "0",
               expected_trn: new_trn
             }
           }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "Confirm you want to merge these teacher records"
      )
      expect(Teacher.exists?(source_id)).to be(true)
      expect(Teacher.exists?(destination.id)).to be(true)
      expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued

      expect {
        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      }.to have_enqueued_job(Teachers::TRN::TRSSyncJob)

      expect(response).to redirect_to(confirmation_path)
      expect(Teacher.exists?(source_id)).to be(false)
      expect(Teacher.exists?(destination.id)).to be(true)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Records merged",
        source_trn,
        new_trn,
        "Back to teachers"
      )
    end

    it "does not merge again when confirmation is submitted twice" do
      source_id = teacher.id
      confirmation_params = {
        confirm: {
          confirmed: "1",
          expected_trn: new_trn
        }
      }

      post entry_path, params: { enter_trn: { trn: new_trn } }
      post preview_path
      post confirm_path, params: confirmation_params

      expect(response).to redirect_to(confirmation_path)
      expect(Teacher.exists?(source_id)).to be(false)
      expect(destination.events.where(event_type: "teacher_merged").count).to eq(1)
      expect(Teachers::TRN::TRSSyncJob)
        .to have_been_enqueued.exactly(:once)

      post confirm_path, params: confirmation_params

      expect(response).to redirect_to(confirmation_path)
      expect(Teacher.exists?(source_id)).to be(false)
      expect(Teacher.exists?(destination.id)).to be(true)
      expect(destination.events.where(event_type: "teacher_merged").count).to eq(1)
      expect(Teachers::TRN::TRSSyncJob)
        .to have_been_enqueued.exactly(:once)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Records merged")
    end

    context "when merge confirmation is rejected" do
      context "when both teachers have induction records" do
        before do
          FactoryBot.create(:induction_period, teacher:)
          post entry_path, params: { enter_trn: { trn: new_trn } }
          post preview_path

          FactoryBot.create(:induction_period, teacher: destination)

          post confirm_path,
               params: { confirm: { confirmed: "1", expected_trn: new_trn } }
        end

        it "shows the cannot use TRN page" do
          expect(response).to redirect_to(cannot_use_trn_path)

          get confirm_path

          expect(response).to redirect_to(entry_path)
        end

        it_behaves_like "does not merge the teacher records"
      end

      context "when the wizard raises TeacherNotDeactivatedError" do
        let(:wizard_store) { FactoryBot.build(:session_repository) }
        let(:wizard) do
          instance_double(
            Admin::Teachers::ChangeTRNWizard::Wizard,
            store: wizard_store,
            allowed_steps: [:confirm],
            allowed_step?: true
          )
        end

        before do
          post entry_path, params: { enter_trn: { trn: new_trn } }
          post preview_path

          wizard_store.trn = new_trn
          step = Admin::Teachers::ChangeTRNWizard::ConfirmStep.new(
            wizard:, confirmed: "1", expected_trn: new_trn
          )
          allow(wizard).to receive(:current_step).and_return(step)
          allow(wizard).to receive(:update!).and_raise(
            Admin::Teachers::ChangeTRNWizard::Wizard::TeacherNotDeactivatedError
          )
          allow(Admin::Teachers::ChangeTRNWizard::Wizard).to receive(:new).and_return(wizard)

          post confirm_path,
               params: { confirm: { confirmed: "1", expected_trn: new_trn } }
        end

        it "redirects to the teacher overview with an explanation" do
          expect(response).to redirect_to(admin_teacher_path(teacher))
          expect(flash[:error]).to eq(
            "This teacher record is no longer deactivated."
          )
        end

        it_behaves_like "does not merge the teacher records"
      end

      context "when the wizard raises MergeProposalChangedError" do
        let(:wizard_store) { FactoryBot.build(:session_repository) }
        let(:wizard) do
          instance_double(
            Admin::Teachers::ChangeTRNWizard::Wizard,
            store: wizard_store,
            allowed_steps: [:confirm],
            allowed_step?: true
          )
        end

        before do
          post entry_path, params: { enter_trn: { trn: new_trn } }
          post preview_path

          wizard_store.trn = new_trn
          step = Admin::Teachers::ChangeTRNWizard::ConfirmStep.new(
            wizard:, confirmed: "1", expected_trn: new_trn
          )
          allow(wizard).to receive(:current_step).and_return(step)
          allow(wizard).to receive(:update!).and_raise(
            Admin::Teachers::ChangeTRNWizard::Wizard::MergeProposalChangedError
          )
          allow(Admin::Teachers::ChangeTRNWizard::Wizard).to receive(:new).and_return(wizard)

          post confirm_path,
               params: { confirm: { confirmed: "1", expected_trn: new_trn } }
        end

        it "returns to TRN entry with an explanation" do
          expect(response).to redirect_to(entry_path)
          expect(flash[:error]).to eq(
            "The teacher records have changed. Enter the replacement TRN and review the records again."
          )
        end

        it_behaves_like "does not merge the teacher records"
      end

      context "when the destination changes during confirmation" do
        let(:expected_destination_trn) { "3456789" }

        before do
          post entry_path, params: { enter_trn: { trn: new_trn } }
          post preview_path
          destination.update!(trn: "3456789")

          post confirm_path,
               params: {
                 confirm: {
                   confirmed: "1",
                   expected_trn: new_trn
                 }
               }
        end

        it "returns to TRN entry with an explanation" do
          expect(response).to redirect_to(entry_path)
          expect(flash[:error]).to eq(
            "The teacher records have changed. Enter the replacement TRN and review the records again."
          )

          get confirm_path

          expect(response).to redirect_to(entry_path)
        end

        it_behaves_like "does not merge the teacher records"
      end

      context "when the source is reactivated before confirmation" do
        before do
          post entry_path, params: { enter_trn: { trn: new_trn } }
          post preview_path
          teacher.update!(trs_response: "ok")

          post confirm_path,
               params: {
                 confirm: {
                   confirmed: "1",
                   expected_trn: new_trn
                 }
               }
        end

        it "redirects to the teacher overview with an explanation" do
          expect(response).to redirect_to(admin_teacher_path(teacher))
          expect(flash[:error]).to eq(
            "This teacher record is no longer deactivated."
          )
        end

        it_behaves_like "does not merge the teacher records"
      end
    end

    context "when confirmation is submitted before the preview" do
      before do
        post entry_path, params: { enter_trn: { trn: new_trn } }

        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      end

      it "requires the preview before allowing merge confirmation" do
        expect(response).to redirect_to(preview_path)
      end

      it_behaves_like "does not merge the teacher records"
    end

    context "when the TRN is submitted again after preview" do
      before do
        post entry_path, params: { enter_trn: { trn: new_trn } }
        post preview_path

        post entry_path, params: { enter_trn: { trn: new_trn } }

        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      end

      it "requires another preview after submitting the TRN again" do
        expect(response).to redirect_to(preview_path)
      end

      it_behaves_like "does not merge the teacher records"
    end

    context "when confirmation is submitted without a replacement TRN" do
      before do
        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      end

      it "prevents merging without first entering a replacement TRN" do
        expect(response).to redirect_to(entry_path)
      end

      it_behaves_like "does not merge the teacher records"
    end

    context "when the replacement TRN changes after review" do
      let(:other_trn) { "3456789" }
      let!(:other_destination) { FactoryBot.create(:teacher, trn: other_trn, trs_response: "ok") }

      before do
        allow(api_client).to receive(:find_teacher)
          .with(trn: other_trn)
          .and_return(trs_teacher)

        post entry_path, params: { enter_trn: { trn: new_trn } }
        post preview_path
        follow_redirect!

        post entry_path, params: { enter_trn: { trn: other_trn } }
        post preview_path

        post confirm_path,
             params: {
               confirm: {
                 confirmed: "1",
                 expected_trn: new_trn
               }
             }
      end

      it "requires another review when the replacement TRN changes" do
        expect(response).to redirect_to(confirm_path)
        expect(flash[:error]).to eq(
          "The proposed TRN has changed. Review the updated details before continuing."
        )
        expect(other_destination.reload.trn).to eq(other_trn)
        expect(other_destination.events.where(event_type: "teacher_merged")).to be_empty
      end

      it_behaves_like "does not merge the teacher records"
    end

    context "when the destination TRN changes before preview" do
      let(:expected_destination_trn) { "3456789" }

      before do
        post entry_path, params: { enter_trn: { trn: new_trn } }
        destination.update!(trn: expected_destination_trn)

        get preview_path
      end

      it "returns to TRN entry with an explanation and clears the proposal" do
        expect(response).to redirect_to(entry_path)
        expect(flash[:error]).to eq(
          "The teacher records have changed. Enter the replacement TRN and review the records again."
        )

        get confirm_path

        expect(response).to redirect_to(entry_path)
      end

      it_behaves_like "does not merge the teacher records"
    end

    it "returns to TRN entry when the destination is deleted" do
      source_id = teacher.id

      post entry_path, params: { enter_trn: { trn: new_trn } }

      destination.destroy!

      get preview_path

      expect(response).to redirect_to(entry_path)
      expect(flash[:error]).to eq(
        "The teacher records have changed. Enter the replacement TRN and review the records again."
      )
      expect(Teacher.exists?(source_id)).to be(true)
      expect(Event.where(event_type: "teacher_merged")).to be_empty
      expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued

      get confirm_path

      expect(response).to redirect_to(entry_path)
    end
  end

  describe "accessing confirmation without entering a TRN" do
    it "redirects GET requests to the entry page" do
      get confirm_path

      expect(response).to redirect_to(entry_path)
    end

    it "prevents direct POST requests from changing the teacher" do
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
