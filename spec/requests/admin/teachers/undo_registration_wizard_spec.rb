RSpec.describe "Admin::Teachers::UndoRegistrationWizardController", type: :request do
  include_context "sign in as DfE user"

  let(:teacher) { FactoryBot.create(:teacher) }
  let!(:at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      started_on: 2.years.ago.to_date,
      finished_on: 1.year.ago.to_date
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      ect_at_school_period: at_school_period,
      started_on: 18.months.ago.to_date,
      finished_on: 1.year.ago.to_date
    )
  end

  let(:declaration) { FactoryBot.create(:declaration, :eligible, training_period:) }

  before { declaration }

  describe "GET start" do
    it "redirects to school history with an explanation" do
      get admin_teacher_undo_registration_wizard_start_path(teacher)

      expect(response).to redirect_to(admin_teacher_school_path(teacher))
      expect(flash[:error]).to eq("There are no open periods to close for this registration.")
    end
  end

  describe "POST confirm" do
    context "when undoing the registration succeeds" do
      let(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
      end

      it "prevents a repeated submission" do
        allow(Events::Record)
          .to receive(:record_undo_registration_event!)
          .and_call_original

        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "close",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: "",
                 expected_at_school_period_gid: at_school_period.to_global_id.to_s
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirmation_path(teacher))
        expect(at_school_period.reload.finished_on).to eq(Date.current)
        expect(training_period.reload.finished_on).to eq(Date.current)

        get admin_teacher_undo_registration_wizard_confirmation_path(teacher)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Associated school, training, and mentorship periods have been closed.")

        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "close",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: "",
                 expected_at_school_period_gid: at_school_period.to_global_id.to_s
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirmation_path(teacher))
        expect(Events::Record).to have_received(:record_undo_registration_event!).once
      end
    end

    context "when undoing an ECT registration without declarations" do
      let(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
      end
      let(:declaration) { nil }

      it "deletes the registration, shows the delete confirmation, and prevents a repeated submission" do
        allow(Events::Record)
          .to receive(:record_undo_registration_event!)
          .and_call_original

        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "delete",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: "",
                 expected_at_school_period_gid: at_school_period.to_global_id.to_s
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirmation_path(teacher))
        expect { at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(teacher.reload.anonymised_at).to be_present

        get admin_teacher_undo_registration_wizard_confirmation_path(teacher)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Associated school, training, and mentorship periods have been deleted.")

        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "delete",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: "",
                 expected_at_school_period_gid: at_school_period.to_global_id.to_s
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirmation_path(teacher))
        expect(Events::Record).to have_received(:record_undo_registration_event!).once
      end
    end

    context "when a reviewed registration has been replaced by another registration" do
      let!(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let!(:remaining_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) { nil }
      let(:declaration) { nil }

      it "does not undo the remaining registration" do
        expected_at_school_period_gid = at_school_period.to_global_id.to_s
        at_school_period.destroy!
        allow(Events::Record)
          .to receive(:record_undo_registration_event!)
          .and_call_original

        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "delete",
                 expected_training_period_ids: "",
                 expected_mentorship_period_ids: "",
                 expected_at_school_period_gid:
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirm_path(teacher))
        expect(flash[:error]).to eq(
          "The registration has changed. Review the updated details before continuing."
        )
        expect { remaining_at_school_period.reload }.not_to raise_error
        expect(Events::Record).not_to have_received(:record_undo_registration_event!)
      end
    end

    context "when undoing a mentor registration with declarations" do
      let(:at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period: at_school_period)
      end

      it "closes the registration and shows the close confirmation" do
        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "close",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: "",
                 expected_at_school_period_gid: at_school_period.to_global_id.to_s
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirmation_path(teacher))
        expect(at_school_period.reload.finished_on).to eq(Date.current)
        expect(training_period.reload.finished_on).to eq(Date.current)

        get admin_teacher_undo_registration_wizard_confirmation_path(teacher)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Associated school, training, and mentorship periods have been closed.")
      end
    end

    context "when the expected action is blank" do
      let(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
      end

      it "does not undo the registration" do
        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: "",
                 expected_at_school_period_gid: at_school_period.to_global_id.to_s
               }
             }

        expect(response).to have_http_status(:unprocessable_content)
        expect(at_school_period.reload.finished_on).to be_nil
        expect(training_period.reload.finished_on).to be_nil
      end
    end
  end
end
