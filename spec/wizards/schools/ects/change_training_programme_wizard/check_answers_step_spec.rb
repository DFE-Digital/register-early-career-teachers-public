describe Schools::ECTs::ChangeTrainingProgrammeWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeTrainingProgrammeWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(
      :session_repository,
      training_programme:,
      lead_provider_id:
    )
  end
  let(:training_programme) { "school_led" }
  let(:lead_provider_id) { nil }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      school:,
      started_on: 1.week.ago
    )
  end
  let(:params) { {} }

  describe "#previous_step" do
    context "when the new training programme is provider_led" do
      let(:training_programme) { "provider_led" }
      let(:training_period) { instance_double(TrainingPeriod, training_programme: "school_led") }

      before do
        allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(training_period)
      end

      it "returns the lead_provider step" do
        expect(current_step.previous_step).to eq(:lead_provider)
      end
    end

    context "when the new training programme is school_led" do
      let(:training_programme) { "school_led" }

      it "returns the edit step" do
        expect(current_step.previous_step).to eq(:edit)
      end
    end
  end

  describe "#next_step" do
    it "returns the confirmation step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#current_training_programme" do
    context "when there is a current_or_next training period" do
      let(:training_period) { instance_double(TrainingPeriod, id: 1, training_programme: "provider_led") }

      before do
        allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(training_period)
      end

      it "returns the current training period's programme" do
        expect(current_step.current_training_programme).to eq("provider_led")
      end
    end

    context "when there is no current_or_next training period but there is a latest training period" do
      let(:latest_training_period) { instance_double(TrainingPeriod, id: 2, training_programme: "provider_led") }

      before do
        allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(nil)
        allow(ect_at_school_period).to receive_messages(current_or_next_training_period: nil, latest_training_period:)
      end

      it "falls back to the latest training period's programme" do
        expect(current_step.current_training_programme).to eq("provider_led")
      end
    end
  end

  describe "#new_training_programme" do
    it "returns the stored training programme" do
      expect(current_step.new_training_programme).to eq(training_programme)
    end
  end

  describe "#new_lead_provider_name" do
    context "when the new training programme is provider_led" do
      let(:training_programme) { "provider_led" }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:lead_provider_id) { lead_provider.id }

      it "returns the name of the lead provider" do
        expect(current_step.new_lead_provider_name).to eq(lead_provider.name)
      end
    end

    context "when the new training programme is school_led" do
      let(:training_programme) { "school_led" }

      it "returns nil" do
        expect(current_step.new_lead_provider_name).to be_nil
      end
    end
  end

  describe "#save!" do
    context "when the new training programme is provider_led" do
      let(:training_programme) { "provider_led" }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:lead_provider_id) { lead_provider.id }
      let(:current_training_period) { instance_double(TrainingPeriod, training_programme: "school_led") }

      before do
        allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(current_training_period)
        allow(ECTAtSchoolPeriods::SwitchTraining)
          .to receive(:to_provider_led)
          .with(ect_at_school_period, author: anything, lead_provider:)
      end

      it "switches the training programme to provider led" do
        current_step.save!

        expect(ECTAtSchoolPeriods::SwitchTraining)
          .to have_received(:to_provider_led)
          .with(ect_at_school_period, author: anything, lead_provider:)
      end

      it "records a `teacher_training_programme_updated` event" do
        freeze_time

        current_step.save!

        event = Event.where(event_type: "teacher_training_programme_updated").sole
        expect(event).to have_attributes(
          ect_at_school_period_id: ect_at_school_period.id,
          school_id: school.id,
          teacher_id: ect_at_school_period.teacher.id
        )
        expect(event.heading).to include("school led", "provider led")
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
      end
    end

    context "when the new training programme is school_led" do
      let(:training_programme) { "school_led" }
      let(:lead_provider_id) { "" }
      let(:current_training_period) { instance_double(TrainingPeriod, training_programme: "provider_led") }

      before do
        allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(current_training_period)
        allow(ECTAtSchoolPeriods::SwitchTraining)
          .to receive(:to_school_led)
          .with(ect_at_school_period, author: anything)
      end

      it "switches the training programme to school led" do
        current_step.save!

        expect(ECTAtSchoolPeriods::SwitchTraining)
          .to have_received(:to_school_led)
          .with(ect_at_school_period, author: anything)
      end

      it "records a `teacher_training_programme_updated` event" do
        freeze_time

        current_step.save!

        event = Event.where(event_type: "teacher_training_programme_updated").sole
        expect(event).to have_attributes(
          ect_at_school_period_id: ect_at_school_period.id,
          school_id: school.id,
          teacher_id: ect_at_school_period.teacher.id
        )
        expect(event.heading).to include("provider led", "school led")
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
      end
    end

    context "when there is no current training period (eg withdrawn ended today)" do
      let(:training_programme) { "school_led" }

      before do
        FactoryBot.create(:training_period, :provider_led, :withdrawn, ect_at_school_period:)
        allow(ect_at_school_period).to receive(:current_or_next_training_period).and_return(nil)

        allow(ECTAtSchoolPeriods::SwitchTraining)
          .to receive(:to_school_led)
          .with(ect_at_school_period, author: anything)
      end

      it "records the old programme from the latest training period" do
        freeze_time

        current_step.save!

        expect(Event.where(event_type: "teacher_training_programme_updated").sole.heading)
          .to include("provider led")
      end
    end
  end
end
