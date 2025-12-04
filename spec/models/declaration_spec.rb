describe Declaration do
  describe "associations" do
    it { is_expected.to belong_to(:training_period) }
    it { is_expected.to belong_to(:voided_by_user).class_name("User").optional }
    it { is_expected.to belong_to(:mentorship_period).optional }
    it { is_expected.to belong_to(:payment_statement).optional }
    it { is_expected.to belong_to(:clawback_statement).optional }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:for_ect?).to(:training_period).allow_nil }
    it { is_expected.to delegate_method(:for_mentor?).to(:training_period).allow_nil }
  end

  describe "validation" do
    it { expect(FactoryBot.build(:declaration)).to be_valid }

    it { is_expected.to validate_presence_of(:training_period).with_message("Choose a training period") }
    it { is_expected.to validate_presence_of(:declaration_date).with_message("Declaration date must be specified") }
    it { is_expected.to validate_absence_of(:ineligibility_reason).with_message("Ineligibility reason must not be set unless the declaration is ineligible") }
    it { is_expected.to validate_inclusion_of(:declaration_type).in_array(described_class.declaration_types.keys).with_message("Choose a valid declaration type") }
    it { is_expected.to validate_inclusion_of(:payment_status).in_array(described_class.payment_statuses.keys).with_message("Choose a valid payment status") }
    it { is_expected.to validate_inclusion_of(:clawback_status).in_array(described_class.clawback_statuses.keys).with_message("Choose a valid clawback status") }
    it { is_expected.to validate_inclusion_of(:evidence_type).in_array(described_class.evidence_types.keys).with_message("Choose a valid evidence type").allow_nil }
    it { is_expected.to validate_inclusion_of(:ineligibility_reason).in_array(described_class.ineligibility_reasons.keys).with_message("Choose a valid ineligibility reason").allow_nil }
    it { is_expected.to validate_uniqueness_of(:api_id).with_message("API id already exists for another declaration").case_insensitive }
    it { is_expected.not_to validate_presence_of(:voided_by_user) }
    it { is_expected.not_to validate_presence_of(:voided_at) }
    it { is_expected.not_to validate_presence_of(:ineligibility_reason) }
    it { is_expected.not_to validate_absence_of(:mentorship_period) }

    context "when payment" do
      subject { FactoryBot.build(:declaration, :paid) }

      it { is_expected.to validate_presence_of(:payment_statement).with_message("Payment statement must be associated for declarations with a payment status") }
    end

    context "when clawback" do
      subject { FactoryBot.build(:declaration, :awaiting_clawback) }

      it { is_expected.to validate_presence_of(:clawback_statement).with_message("Clawback statement must be associated for declarations with a clawback status") }
    end

    context "when the declaration is for a mentor" do
      subject { FactoryBot.build(:declaration, training_period:) }

      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: 1.month.ago, finished_on: nil) }
      let(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: 1.month.ago, finished_on: nil) }

      it { is_expected.to validate_absence_of(:mentorship_period).with_message("Mentorship period must belong to the trainee") }
    end

    context "when voided by a user" do
      subject { FactoryBot.build(:declaration, :voided_by_user) }

      it { is_expected.to validate_presence_of(:voided_by_user).with_message("Voided by user must be set as well as the voided date") }
      it { is_expected.to validate_presence_of(:voided_at).with_message("Voided at must be set as well as the voided by user") }
    end

    context "when ineligible" do
      subject { FactoryBot.build(:declaration, :ineligible) }

      it { is_expected.to validate_presence_of(:ineligibility_reason).with_message("Ineligibility reason must be set when the declaration is ineligible") }
    end

    describe "declaration date relative to milestone dates" do
      subject(:declaration) { FactoryBot.build(:declaration, declaration_type: :started, declaration_date:, training_period:) }

      let(:schedule) { FactoryBot.create(:schedule, contract_period: school_partnership.contract_period) }
      let(:milestone) { FactoryBot.create(:milestone, declaration_type: :started, schedule:) }
      let(:school_partnership) { FactoryBot.create(:school_partnership) }
      let(:training_period) { FactoryBot.create(:training_period, schedule:, school_partnership:) }

      context "when the declaration date is within the milestone dates" do
        let(:declaration_date) { Faker::Date.between(from: milestone.start_date, to: milestone.milestone_date) }

        it { is_expected.to be_valid }
      end

      context "when the declaration date is before the milestone start_date" do
        let(:declaration_date) { milestone.start_date - 1.day }

        it "is not valid" do
          expect(declaration).not_to be_valid
          expect(declaration.errors[:declaration_date]).to include("Declaration date must be on or after the milestone start date for the same declaration type")
        end
      end

      context "when the declaration date is after the milestone_date" do
        let(:declaration_date) { milestone.milestone_date + 1.day }

        it "is not valid" do
          expect(declaration).not_to be_valid
          expect(declaration.errors[:declaration_date]).to include("Declaration date must be on or before the milestone date for the same declaration type")
        end
      end

      describe "contract period consistent across associations" do
        let(:training_period) { FactoryBot.create(:training_period) }

        let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: training_period.contract_period) }
        let(:statement) { FactoryBot.create(:statement, active_lead_provider:) }

        let(:mismatch_contract_period) { FactoryBot.create(:contract_period, year: training_period.contract_period.year + 1) }
        let(:mismatch_active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: mismatch_contract_period) }
        let(:mismatch_statement) { FactoryBot.create(:statement, active_lead_provider: mismatch_active_lead_provider) }

        context "checking contract period matches with payment statement" do
          context "when contract periods match" do
            subject { FactoryBot.build(:declaration, training_period:, payment_statement: statement) }

            it { is_expected.to be_valid }
          end

          context "when contract periods do not match" do
            subject { FactoryBot.build(:declaration, training_period:, payment_statement: mismatch_statement) }

            it "adds an error to schedule" do
              expect(subject).to be_invalid
              expect(subject.errors[:training_period]).to include("Contract period mismatch: training period, payment_statement and clawback_statement must have the same contract period.")
            end
          end
        end

        context "checking contract period matches with clawback statement" do
          context "when contract periods match" do
            subject { FactoryBot.build(:declaration, training_period:, clawback_statement: statement) }

            it { is_expected.to be_valid }
          end

          context "when contract periods do not match" do
            subject { FactoryBot.build(:declaration, training_period:, clawback_statement: mismatch_statement) }

            it "adds an error to schedule" do
              expect(subject).to be_invalid
              expect(subject.errors[:training_period]).to include("Contract period mismatch: training period, payment_statement and clawback_statement must have the same contract period.")
            end
          end
        end
      end
    end

    describe "mentorship_period" do
      subject(:declaration) { FactoryBot.build(:declaration, mentorship_period:, training_period:) }

      let(:started_on) { 1.month.ago }
      let(:mentor) { FactoryBot.create(:mentor_at_school_period, started_on:, finished_on: nil) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on:, finished_on: nil) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on:, finished_on: nil) }

      context "when the mentorship_period does not belong to the trainee" do
        let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on:, finished_on: nil) }
        let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor:, mentee:, started_on:, finished_on: nil) }

        it "is not valid" do
          expect(declaration).not_to be_valid
          expect(declaration.errors[:mentorship_period]).to include("Mentorship period must belong to the trainee")
        end
      end

      context "when the mentorship_period does belong to the trainee" do
        let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor:, mentee: training_period.trainee, finished_on: nil) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "enums" do
    it "has a payment_status enum" do
      expect(subject).to define_enum_for(:payment_status)
        .with_values({
          no_payment: "no_payment",
          eligible: "eligible",
          payable: "payable",
          paid: "paid",
          voided: "voided",
          ineligible: "ineligible",
        })
        .validating(allowing_nil: false)
        .backed_by_column_of_type(:enum)
        .with_prefix
    end

    it "has a clawback_status enum" do
      expect(subject).to define_enum_for(:clawback_status)
        .with_values({
          no_clawback: "no_clawback",
          awaiting_clawback: "awaiting_clawback",
          clawed_back: "clawed_back"
        })
        .validating(allowing_nil: false)
        .backed_by_column_of_type(:enum)
        .with_prefix
    end

    it "has a declaration_type enum" do
      expect(subject).to define_enum_for(:declaration_type)
        .with_values({
          started: "started",
          "retained-1": "retained-1",
          "retained-2": "retained-2",
          "retained-3": "retained-3",
          "retained-4": "retained-4",
          "extended-1": "extended-1",
          "extended-2": "extended-2",
          "extended-3": "extended-3",
          completed: "completed"
        })
        .backed_by_column_of_type(:enum)
        .validating(allowing_nil: false)
    end

    it "has a evidence_type enum" do
      expect(subject).to define_enum_for(:evidence_type)
        .with_values({
          "training-event-attended": "training-event-attended",
          "self-study-material-completed": "self-study-material-completed",
          "materials-engaged-with-offline": "materials-engaged-with-offline",
          "75-percent-engagement-met": "75-percent-engagement-met",
          "75-percent-engagement-met-reduced-induction": "75-percent-engagement-met-reduced-induction",
          "one-term-induction": "one-term-induction",
          other: "other"
        })
        .backed_by_column_of_type(:enum)
        .validating(allowing_nil: true)
    end

    it "has an ineligibility_reason enum" do
      expect(subject).to define_enum_for(:ineligibility_reason)
        .with_values({
          duplicate: "duplicate"
        })
        .backed_by_column_of_type(:enum)
        .validating(allowing_nil: true)
    end
  end

  describe "scopes" do
    describe ".completed" do
      it "returns completed declarations" do
        FactoryBot.create(:declaration, declaration_type: "started")
        completed_dec = FactoryBot.create(:declaration, declaration_type: "completed")
        expect(described_class.completed).to contain_exactly(completed_dec)
      end
    end

    describe ".billable" do
      it "returns billable declarations" do
        FactoryBot.create(:declaration, %i[not_started voided ineligible].sample)
        billable_dec = FactoryBot.create(:declaration, %i[eligible payable paid].sample)
        expect(described_class.billable.to_a).to eq([billable_dec])
      end
    end
  end

  describe "payment_status transitions" do
    context "when transitioning from no_payment to eligible" do
      let(:declaration) { FactoryBot.create(:declaration).tap { it.payment_statement = FactoryBot.create(:statement, :open, contract_period: it.training_period.contract_period) } }

      it { expect { declaration.mark_as_eligible! }.to change(declaration, :payment_status).from("no_payment").to("eligible") }
    end

    context "when transitioning from eligible to payable" do
      let(:declaration) { FactoryBot.create(:declaration, :eligible) }

      it { expect { declaration.mark_as_payable! }.to change(declaration, :payment_status).from("eligible").to("payable") }
    end

    context "when transitioning from payable to paid" do
      let(:declaration) { FactoryBot.create(:declaration, :payable) }

      it { expect { declaration.mark_as_paid! }.to change(declaration, :payment_status).from("payable").to("paid") }
    end

    context "when transitioning from eligible to voided" do
      let(:declaration) { FactoryBot.create(:declaration, :eligible) }

      it { expect { declaration.mark_as_voided! }.to change(declaration, :payment_status).from("eligible").to("voided") }
    end

    context "when transitioning from ineligible to voided" do
      let(:declaration) { FactoryBot.create(:declaration, :ineligible) }

      it { expect { declaration.mark_as_voided! }.to change(declaration, :payment_status).from("ineligible").to("voided") }
      it { expect { declaration.mark_as_voided! }.to change(declaration, :ineligibility_reason).to(nil) }
    end

    context "when transitioning from payable to voided" do
      let(:declaration) { FactoryBot.create(:declaration, :payable) }

      it { expect { declaration.mark_as_voided! }.to change(declaration, :payment_status).from("payable").to("voided") }
    end

    context "when transitioning from no_payment to ineligible" do
      let(:reason) { described_class.ineligibility_reasons.keys.sample }
      let(:declaration) do
        FactoryBot.create(:declaration).tap do
          it.ineligibility_reason = reason
          it.payment_statement = FactoryBot.create(:statement, :open, contract_period: it.training_period.contract_period)
        end
      end

      it { expect { declaration.mark_as_ineligible! }.to change(declaration, :payment_status).from("no_payment").to("ineligible") }
    end

    context "when transitioning to an invalid state" do
      let(:declaration) { FactoryBot.create(:declaration, :paid) }

      it { expect { declaration.mark_as_paid! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end

  describe "clawback_status transitions" do
    context "when transitioning from no_clawback to awaiting_clawback" do
      let(:declaration) { FactoryBot.create(:declaration, :paid).tap { it.clawback_statement = FactoryBot.create(:statement, :payable, contract_period: it.training_period.contract_period) } }

      it { expect { declaration.mark_as_awaiting_clawback! }.to change(declaration, :clawback_status).from("no_clawback").to("awaiting_clawback") }
    end

    context "when transitioning from no_clawback to awaiting_clawback, when the declaration is not paid" do
      let(:declaration) { FactoryBot.create(:declaration, :payable).tap { it.clawback_statement = FactoryBot.create(:statement, :payable, contract_period: it.training_period.contract_period) } }

      it { expect { declaration.mark_as_awaiting_clawback! }.to raise_error(StateMachines::InvalidTransition) }
    end

    context "when transitioning from awaiting_clawback to clawed_back" do
      let(:declaration) { FactoryBot.create(:declaration, :awaiting_clawback) }

      it { expect { declaration.mark_as_clawed_back! }.to change(declaration, :clawback_status).from("awaiting_clawback").to("clawed_back") }
    end

    context "when transitioning to an invalid state" do
      let(:declaration) { FactoryBot.create(:declaration, :clawed_back) }

      it { expect { declaration.mark_as_clawed_back! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end
end
