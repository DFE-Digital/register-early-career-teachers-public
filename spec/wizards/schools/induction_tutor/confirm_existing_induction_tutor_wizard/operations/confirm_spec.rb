RSpec.describe Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Operations::Confirm do
  subject(:operation) { described_class.new(repository: state_store.repository, step: wizard.current_step) }

  let(:wizard) do
    Schools::InductionTutor::ConfirmExistingInductionTutorWizard::Wizard.new(
      state_store:,
      current_step: :edit,
      current_step_params: { edit: { are_these_details_correct: } }
    )
  end
  let(:state_store) { Schools::InductionTutor::StateStore.new(school:) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:are_these_details_correct) { true }

  let!(:previous_contract_period) do
    FactoryBot.create(:contract_period, :previous, started_on: 2.months.ago, finished_on: 1.month.ago.prev_day)
  end
  let!(:upcoming_contract_period) do
    FactoryBot.create(:contract_period, :next, started_on: 2.months.from_now, finished_on: 6.months.from_now)
  end
  let(:school) do
    FactoryBot.create(:school, :with_induction_tutor, induction_tutor_last_nominated_in: previous_contract_period)
  end

  before { allow(wizard).to receive(:author).and_return(author) }

  context "when the current contract period is ongoing today" do
    let!(:current_contract_period) do
      FactoryBot.create(:contract_period, :current, started_on: 1.month.ago, finished_on: 1.month.from_now)
    end

    it "succeeds" do
      expect(operation.execute).to eq(success: true)
    end

    it "nominates the induction tutor in the current contract period" do
      expect { operation.execute }
        .to change { school.reload.induction_tutor_last_nominated_in }
        .from(previous_contract_period)
        .to(current_contract_period)
    end

    it "does not change the induction tutor details" do
      expect { operation.execute }
        .to not_change { school.reload.induction_tutor_name }
        .and(not_change { school.reload.induction_tutor_email })
    end

    it "records a confirmation event" do
      operation.execute

      event = Event.where(event_type: "school_induction_tutor_confirmed").sole
      expect(event.school_id).to eq(school.id)
      expect(event.metadata).to eq(
        "contract_period_year" => current_contract_period.year,
        "name" => school.induction_tutor_name,
        "email" => school.induction_tutor_email
      )
    end

    it "does not send a confirmation email" do
      expect { operation.execute }
        .not_to have_enqueued_mail(Schools::InductionTutorConfirmationMailer, :confirmation)
    end
  end

  context "when the current contract period has finished" do
    before { FactoryBot.create(:contract_period, :current, started_on: 1.month.ago, finished_on: 1.day.ago) }

    it "nominates the induction tutor in the upcoming contract period" do
      expect { operation.execute }
        .to change { school.reload.induction_tutor_last_nominated_in }
        .from(previous_contract_period)
        .to(upcoming_contract_period)
    end

    it "records a confirmation event for the upcoming contract period" do
      operation.execute

      event = Event.where(event_type: "school_induction_tutor_confirmed").sole
      expect(event.metadata).to include("contract_period_year" => upcoming_contract_period.year)
    end
  end

  context "when the user has said the details are not correct" do
    let(:are_these_details_correct) { false }

    it "succeeds" do
      expect(operation.execute).to eq(success: true)
    end

    it "does not update the school" do
      expect { operation.execute }.not_to(change { school.reload.attributes })
    end

    it "does not record any events" do
      expect { operation.execute }.not_to change(Event, :count)
    end
  end
end
