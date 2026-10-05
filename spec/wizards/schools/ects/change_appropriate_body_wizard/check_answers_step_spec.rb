describe Schools::ECTs::ChangeAppropriateBodyWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeAppropriateBodyWizard::Wizard.new(
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
      appropriate_body_id: new_appropriate_body_period.id
    )
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:teacher) { ect_at_school_period.teacher }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, school_reported_appropriate_body: old_appropriate_body_period) }
  let(:params) { { appropriate_body_id: new_appropriate_body_period.id } }
  let(:new_appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:old_appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  describe "#previous_step" do
    it "returns the state school step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the confirmation step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#old_appropriate_body_name" do
    it "returns the current appropriate body's name" do
      expect(current_step.old_appropriate_body_name).to eq(old_appropriate_body_period.name)
    end

    context "when the current appropriate body is nil" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
      let(:old_appropriate_body_period) { nil }

      it "returns 'Not reported'" do
        expect(current_step.old_appropriate_body_name).to eq("Not reported")
      end
    end

    context "when the period has no name of its own" do
      let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "Star Teaching School Hub Network") }
      let(:old_appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub, name: nil, teaching_school_hub:)
      end

      it "delegates to the parent hub" do
        expect(current_step.old_appropriate_body_name).to eq("Star Teaching School Hub Network")
      end
    end
  end

  describe "#new_appropriate_body_name" do
    it "returns the selected appropriate body's name" do
      expect(current_step.new_appropriate_body_name).to eq(new_appropriate_body_period.name)
    end

    context "when the period has no name of its own" do
      let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "Star Teaching School Hub Network") }
      let(:new_appropriate_body_period) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub, name: nil, teaching_school_hub:)
      end

      it "delegates to the parent hub" do
        expect(current_step.new_appropriate_body_name).to eq("Star Teaching School Hub Network")
      end
    end
  end

  describe "#save!" do
    it "changes the appropriate body" do
      expect { current_step.save! }
        .to change { ect_at_school_period.reload.school_reported_appropriate_body }
        .from(old_appropriate_body_period)
        .to(new_appropriate_body_period)
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end

    it "records an event" do
      current_step.save!

      event = Event.where(event_type: "teacher_appropriate_body_changed").sole
      expect(event).to have_attributes(
        teacher_id: ect_at_school_period.teacher_id,
        ect_at_school_period_id: ect_at_school_period.id,
        appropriate_body_period_id: new_appropriate_body_period.id
      )
      expect(event.heading).to include(old_appropriate_body_period.name, new_appropriate_body_period.name)
    end

    context "when the new period has no name of its own" do
      let(:new_appropriate_body_period) do
        FactoryBot.create(
          :appropriate_body_period,
          :teaching_school_hub,
          name: nil,
          teaching_school_hub: FactoryBot.create(:teaching_school_hub, name: "Star Teaching School Hub Network")
        )
      end

      it "changes the appropriate body and records the event against it" do
        expect { current_step.save! }
          .to change { ect_at_school_period.reload.school_reported_appropriate_body }
          .from(old_appropriate_body_period)
          .to(new_appropriate_body_period)

        event = Event.where(event_type: "teacher_appropriate_body_changed").sole
        expect(event).to have_attributes(
          ect_at_school_period_id: ect_at_school_period.id,
          appropriate_body_period_id: new_appropriate_body_period.id
        )
        expect(event.heading).to include(old_appropriate_body_period.name, "Star Teaching School Hub Network")
      end
    end
  end
end
