describe Schools::InductionTutor::NewInductionTutorWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::InductionTutor::NewInductionTutorWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      school_id: school.id
    )
  end

  let(:store)  { FactoryBot.build(:session_repository, induction_tutor_email:, induction_tutor_name:) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school, :without_induction_tutor) }
  let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }

  let(:induction_tutor_email) { Faker::Internet.email }
  let(:induction_tutor_name) { Faker::Name.name }

  let(:params) { {} }

  describe "#previous_step" do
    it "returns the previous step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the next step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#save!" do
    context "when the current contract period is ongoing today" do
      let!(:current_contract_period) do
        FactoryBot.create(
          :contract_period,
          :current,
          started_on: 1.month.ago,
          finished_on: 1.month.from_now
        )
      end
      let!(:upcoming_contract_period) do
        FactoryBot.create(
          :contract_period,
          :next,
          started_on: 2.months.from_now,
          finished_on: 6.months.from_now
        )
      end

      it "assigns the induction_tutor_last_nominated_in" do
        expect { current_step.save! }
          .to change { school.reload.induction_tutor_last_nominated_in }
          .from(nil)
          .to(current_contract_period)
      end

      it "records an event" do
        freeze_time

        expect(Events::Record)
          .to receive(:record_school_induction_tutor_updated_event!)
          .with(
            author:,
            school:,
            old_name: school.induction_tutor_name,
            new_name: induction_tutor_name,
            new_email: induction_tutor_email,
            contract_period_year: current_contract_period.year
          )

        current_step.save!
      end
    end

    context "when the current contract period has finished" do
      let!(:current_contract_period) do
        FactoryBot.create(
          :contract_period,
          :current,
          started_on: 1.month.ago,
          finished_on: 1.day.ago
        )
      end
      let!(:upcoming_contract_period) do
        FactoryBot.create(
          :contract_period,
          :next,
          started_on: 2.months.from_now,
          finished_on: 6.months.from_now
        )
      end

      it "assigns the induction_tutor_last_nominated_in" do
        expect { current_step.save! }
          .to change { school.reload.induction_tutor_last_nominated_in }
          .from(nil)
          .to(upcoming_contract_period)
      end

      it "records an event" do
        freeze_time

        expect(Events::Record)
          .to receive(:record_school_induction_tutor_updated_event!)
          .with(
            author:,
            school:,
            old_name: school.induction_tutor_name,
            new_name: induction_tutor_name,
            new_email: induction_tutor_email,
            contract_period_year: upcoming_contract_period.year
          )

        current_step.save!
      end
    end

    it "updates the school's induction tutor details" do
      current_step.save!

      school.reload
      expect(school.induction_tutor_email).to eq(induction_tutor_email)
      expect(school.induction_tutor_name).to eq(induction_tutor_name)
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end

    it "sends a confirmation email" do
      expect { current_step.save! }
        .to have_enqueued_mail(Schools::InductionTutorConfirmationMailer, :confirmation)
    end
  end
end
