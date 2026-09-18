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

  before { FactoryBot.create(:declaration, :eligible, training_period:) }

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
                 expected_mentorship_period_ids: ""
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
                 expected_mentorship_period_ids: ""
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirmation_path(teacher))
        expect(Events::Record).to have_received(:record_undo_registration_event!).once
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
                 expected_mentorship_period_ids: ""
               }
             }

        expect(response).to have_http_status(:unprocessable_content)
        expect(at_school_period.reload.finished_on).to be_nil
        expect(training_period.reload.finished_on).to be_nil
      end
    end

    context "when the service finds no open periods to close" do
      let(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
      end
      let(:undo_registration_service) do
        instance_double(
          ::Teachers::UndoRegistration,
          undoable?: true
        )
      end

      before do
        allow(::Teachers::UndoRegistration).to receive(:new).and_return(undo_registration_service)
        allow(undo_registration_service).to receive(:undo!)
          .and_raise(::Teachers::UndoRegistration::NoPeriodsToCloseError)
      end

      it "redirects to school history with an explanation" do
        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "close",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: ""
               }
             }

        expect(response).to redirect_to(admin_teacher_school_path(teacher))
        expect(flash[:error]).to eq("There are no open periods to close for this registration.")
      end
    end

    context "when the undo outcome has changed" do
      let(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
      end
      let(:undo_registration_service) do
        instance_double(
          ::Teachers::UndoRegistration,
          undoable?: true
        )
      end

      before do
        allow(::Teachers::UndoRegistration).to receive(:new).and_return(undo_registration_service)
        allow(undo_registration_service).to receive(:undo!)
          .and_raise(::Teachers::UndoRegistration::UndoOutcomeChangedError)
      end

      it "redirects to confirmation so the updated outcome can be reviewed" do
        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "delete",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: ""
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirm_path(teacher))
        expect(flash[:error]).to eq(
          "The declarations for this registration have changed. Review the updated outcome before continuing."
        )
      end
    end

    context "when the affected periods have changed" do
      let(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
      end
      let(:undo_registration_service) do
        instance_double(
          ::Teachers::UndoRegistration,
          undoable?: true
        )
      end

      before do
        allow(::Teachers::UndoRegistration).to receive(:new).and_return(undo_registration_service)
        allow(undo_registration_service).to receive(:undo!)
          .and_raise(::Teachers::UndoRegistration::AffectedPeriodsChangedError)
      end

      it "redirects to confirmation so the updated periods can be reviewed" do
        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "close",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: ""
               }
             }

        expect(response).to redirect_to(admin_teacher_undo_registration_wizard_confirm_path(teacher))
        expect(flash[:error]).to eq(
          "The periods for this registration have changed. Review the updated periods before continuing."
        )
      end
    end

    context "when the registration has already been undone" do
      let(:at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, teacher:)
      end
      let(:training_period) do
        FactoryBot.create(:training_period, :for_ect, :unfinished, ect_at_school_period: at_school_period)
      end
      let(:undo_registration_service) do
        instance_double(
          ::Teachers::UndoRegistration,
          undoable?: true
        )
      end

      before do
        allow(::Teachers::UndoRegistration).to receive(:new).and_return(undo_registration_service)
        allow(undo_registration_service).to receive(:undo!)
          .and_raise(::Teachers::UndoRegistration::RegistrationAlreadyUndoneError)
      end

      it "redirects to school history with an explanation" do
        post admin_teacher_undo_registration_wizard_confirm_path(teacher),
             params: {
               confirm: {
                 confirmed: "1",
                 expected_action: "close",
                 expected_training_period_ids: training_period.id.to_s,
                 expected_mentorship_period_ids: ""
               }
             }

        expect(response).to redirect_to(admin_teacher_school_path(teacher))
        expect(flash[:error]).to eq("This registration has already been undone.")
      end
    end
  end
end
