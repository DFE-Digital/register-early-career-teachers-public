RSpec.describe Schools::InductionTutor::Operations::Update do
  subject(:operation) { described_class.new(repository: state_store.repository, step: wizard.current_step) }

  let(:wizard) do
    Schools::InductionTutor::NewInductionTutorWizard::Wizard.new(state_store:, current_step: :check_answers)
  end
  let(:state_store) { Schools::InductionTutor::StateStore.new(school:) }
  let(:school) { FactoryBot.create(:school, :without_induction_tutor) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }

  before do
    state_store.write(induction_tutor_name: "New Name", induction_tutor_email: "new.name@example.com")
    allow(wizard).to receive(:author).and_return(author)
  end

  shared_examples "updates the induction tutor" do
    it "succeeds" do
      expect(operation.execute).to eq(success: true)
    end

    it "updates the induction tutor details" do
      expect { operation.execute }
        .to change { school.reload.induction_tutor_name }.to("New Name")
        .and change { school.reload.induction_tutor_email }.to("new.name@example.com")
    end

    it "sends a confirmation email" do
      expect { operation.execute }
        .to have_enqueued_mail(Schools::InductionTutorConfirmationMailer, :confirmation)
    end
  end

  context "when the current contract period is ongoing today" do
    let!(:current_contract_period) do
      FactoryBot.create(:contract_period, :current, started_on: 1.month.ago, finished_on: 1.month.from_now)
    end

    before { FactoryBot.create(:contract_period, :next, started_on: 2.months.from_now, finished_on: 6.months.from_now) }

    it_behaves_like "updates the induction tutor"

    it "nominates the induction tutor in the current contract period" do
      expect { operation.execute }
        .to change { school.reload.induction_tutor_last_nominated_in }.from(nil).to(current_contract_period)
    end

    it "records an event" do
      operation.execute

      event = Event.where(event_type: "school_induction_tutor_updated").sole
      expect(event.school_id).to eq(school.id)
      expect(event.metadata).to eq(
        "contract_period_year" => current_contract_period.year,
        "name" => "New Name",
        "email" => "new.name@example.com"
      )
      expect(event.heading).to include("New Name")
    end
  end

  context "when the current contract period has finished" do
    let!(:upcoming_contract_period) do
      FactoryBot.create(:contract_period, :next, started_on: 2.months.from_now, finished_on: 6.months.from_now)
    end

    before { FactoryBot.create(:contract_period, :current, started_on: 1.month.ago, finished_on: 1.day.ago) }

    it_behaves_like "updates the induction tutor"

    it "nominates the induction tutor in the upcoming contract period" do
      expect { operation.execute }
        .to change { school.reload.induction_tutor_last_nominated_in }.from(nil).to(upcoming_contract_period)
    end

    it "records an event for the upcoming contract period" do
      operation.execute

      event = Event.where(event_type: "school_induction_tutor_updated").sole
      expect(event.metadata).to include("contract_period_year" => upcoming_contract_period.year)
    end
  end

  context "when there is no current or upcoming contract period" do
    it_behaves_like "updates the induction tutor"

    it "does not change when the induction tutor was last nominated" do
      expect { operation.execute }.not_to(change { school.reload.induction_tutor_last_nominated_in })
    end

    it "records an event without a contract period" do
      operation.execute

      event = Event.where(event_type: "school_induction_tutor_updated").sole
      expect(event.metadata).to include("contract_period_year" => nil)
    end
  end
end
