describe Schools::InductionTutor::ConfirmExistingInductionTutorWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      school_id: school.id
    )
  end

  let(:store)  { FactoryBot.build(:session_repository, induction_tutor_email:, induction_tutor_name:) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }
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
    context "when the induction tutor details are confirmed as correct" do
      
      before { store.are_these_details_correct = true }

      it "updates the school's induction tutor details and sets induction_tutor_last_nominated_in" do
        current_step.save!

        school.reload
        expect(school.induction_tutor_email).to eq(induction_tutor_email)
        expect(school.induction_tutor_name).to eq(induction_tutor_name)
        expect(school.induction_tutor_last_nominated_in).to eq(current_contract_period)
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
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

      it "does not send a confirmation email" do
        expect { current_step.save! }
          .not_to have_enqueued_mail(Schools::InductionTutorConfirmationMailer, :confirmation)
      end
    end

    context "when the induction tutor details are not confirmed as correct" do
      before { store.are_these_details_correct = false }

      it "sends a confirmation email" do
        expect { current_step.save! }
          .to have_enqueued_mail(Schools::InductionTutorConfirmationMailer, :confirmation)
      end
    end

    context "on the last day of the contract period" do
      around do |example|
        travel_to current_contract_period.finished_on do
          example.run
        end
      end

      it "finds the contract period and saves to the database" do
        expect(current_step.save!).to be_truthy
      end

      it "records an event linked to the correct contract period" do
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
  end
end
