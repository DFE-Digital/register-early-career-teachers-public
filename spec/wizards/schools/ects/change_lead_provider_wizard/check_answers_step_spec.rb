describe Schools::ECTs::ChangeLeadProviderWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeLeadProviderWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(:session_repository, lead_provider_id: lead_provider.id)
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:contract_period) do
    FactoryBot.create(:contract_period, :current)
  end
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      school:,
      started_on: contract_period.started_on + 1.week
    )
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:active_lead_provider) do
    FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period:
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      :provider_led,
      :with_only_expression_of_interest,
      ect_at_school_period:,
      started_on: ect_at_school_period.started_on
    )
  end
  let(:params) { {} }

  describe "#previous_step" do
    it "returns the edit step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the confirmation step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#new_lead_provider_name" do
    it "returns the selected lead provider's name" do
      expect(current_step.new_lead_provider_name).to eq(lead_provider.name)
    end
  end

  describe "#save!" do
    context "when there is an existing school partnership" do
      let(:school_partnership) do
        FactoryBot.create(
          :school_partnership,
          school: ect_at_school_period.school
        )
      end

      before { training_period.update!(school_partnership:) }

      context "when the date of transition is today" do
        it "finishes the existing training period" do
          freeze_time

          current_step.save!

          expect { training_period.reload }.not_to raise_error
          expect(training_period.finished_on).to eq(Date.current)
        end

        it "creates a new training period with the new lead provider" do
          current_step.save!

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(Date.current)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          current_step.save!
        end
      end

      context "when the date of transition is in the future" do
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :ongoing,
            school:,
            started_on: 1.month.from_now
          )
        end

        it "destroys the existing training period" do
          freeze_time

          current_step.save!

          expect { training_period.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it "creates a new training period" do
          current_step.save!

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(ect_at_school_period.started_on)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          current_step.save!
        end
      end
    end

    context "when there is no existing school partnership" do
      context "when the date of transition is today" do
        it "destroys the existing training period" do
          freeze_time

          current_step.save!

          expect { training_period.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it "creates a new training period" do
          current_step.save!

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(Date.current)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.expression_of_interest.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          current_step.save!
        end
      end

      context "when the date of transition is in the future" do
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :ongoing,
            school:,
            started_on: 1.month.from_now
          )
        end

        it "destroys the existing training period" do
          freeze_time

          current_step.save!

          expect { training_period.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it "creates a new training period" do
          current_step.save!

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(ect_at_school_period.started_on)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.expression_of_interest.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          current_step.save!
        end
      end
    end
  end
end
