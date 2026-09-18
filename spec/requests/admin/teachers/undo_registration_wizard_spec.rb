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
             params: { confirm: { confirmed: "1" } }

        expect(response).to redirect_to(admin_teacher_school_path(teacher))
        expect(flash[:error]).to eq("There are no open periods to close for this registration.")
      end
    end
  end
end
