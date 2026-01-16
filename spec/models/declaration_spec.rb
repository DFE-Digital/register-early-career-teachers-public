describe Declaration do
  describe "declarative updates" do
    def will_change_attribute(attribute_to_change:, new_value:)
      FactoryBot.create(:statement, id: new_value) if attribute_to_change.in?(%i[payment_statement_id clawback_statement_id])
    end

    describe "declarative touch target self" do
      let(:instance) { FactoryBot.create(:declaration) }
      let(:target) { instance }

      it_behaves_like "a declarative touch model", when_changing: %i[
        api_id
        mentorship_period_id
        training_period_id
        payment_statement_id
        clawback_statement_id
        declaration_type
        declaration_date
        payment_status
        clawback_status
        ineligibility_reason
        sparsity_uplift
        pupil_premium_uplift
        evidence_type
      ], timestamp_attribute: :api_updated_at
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:training_period) }
    it { is_expected.to belong_to(:voided_by_user).class_name("User").optional }
    it { is_expected.to belong_to(:mentorship_period).optional }
    it { is_expected.to belong_to(:payment_statement).optional }
    it { is_expected.to belong_to(:clawback_statement).optional }
    it { is_expected.to have_one(:lead_provider).through(:training_period) }
    it { is_expected.to have_one(:delivery_partner).through(:training_period) }
    it { is_expected.to have_one(:contract_period).through(:training_period) }
    it { is_expected.to have_one(:ect_at_school_period).through(:training_period) }
    it { is_expected.to have_one(:mentor_at_school_period).through(:training_period) }
    it { is_expected.to have_one(:ect_teacher).through(:ect_at_school_period).source(:teacher) }
    it { is_expected.to have_one(:mentor_teacher).through(:mentor_at_school_period).source(:teacher) }
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
    it { is_expected.not_to validate_presence_of(:voided_by_user_at) }
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
      it { is_expected.to validate_presence_of(:voided_by_user_at).with_message("Voided by user at must be set as well as the voided by user") }
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
          expect(declaration.errors[:declaration_date]).to include("Declaration date must be on or after the milestone start date for the same declaration type.")
        end
      end

      context "when the declaration date is after the milestone_date" do
        let(:declaration_date) { milestone.milestone_date + 1.day }

        it "is not valid" do
          expect(declaration).not_to be_valid
          expect(declaration.errors[:declaration_date]).to include("Declaration date must be on or before the milestone date for the same declaration type.")
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
      let(:school) { FactoryBot.create(:school) }
      let(:mentor) { FactoryBot.create(:mentor_at_school_period, school:, started_on:, finished_on: nil) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on:, finished_on: nil) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on:, finished_on: nil) }

      context "when the mentorship_period does not belong to the trainee" do
        let(:mentee) { FactoryBot.create(:ect_at_school_period, school:, started_on:, finished_on: nil) }
        let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor:, mentee:, started_on:, finished_on: nil) }

        it "is not valid" do
          expect(declaration).not_to be_valid
          expect(declaration.errors[:mentorship_period]).to include("Mentorship period must belong to the trainee")
        end
      end

      context "when the mentorship_period does belong to the trainee" do
        let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor:, mentee: training_period.at_school_period, finished_on: nil) }

        it { is_expected.to be_valid }
      end
    end

    describe "declaration type for mentor funding enabled contract periods" do
      context "when the contract period has mentor_funding_enabled" do
        before { training_period.contract_period.update(mentor_funding_enabled: true) }

        let(:training_period) { FactoryBot.create(:training_period, :for_mentor) }

        %w[started completed].each do |allowed_type|
          context "when the declaration_type is #{allowed_type}" do
            subject { FactoryBot.build(:declaration, training_period:, declaration_type: allowed_type) }

            it { is_expected.to be_valid }
          end
        end

        described_class.declaration_types.keys.excluding("started", "completed").each do |disallowed_type|
          context "when the declaration_type is #{disallowed_type}" do
            subject { FactoryBot.build(:declaration, training_period:, declaration_type: disallowed_type) }

            it "is not valid" do
              expect(subject).not_to be_valid
              expect(subject.errors[:declaration_type]).to include("Only 'started' or 'completed' declaration types are allowed for mentor funding enabled contract periods.")
            end

            context "when the training period is for an ECT" do
              let(:training_period) { FactoryBot.create(:training_period, :for_ect) }

              it { is_expected.to be_valid }
            end
          end
        end
      end
    end

    describe "existing declarations" do
      subject { FactoryBot.build(:declaration, :eligible, training_period:, declaration_type: :started) }

      let(:training_period) { FactoryBot.create(:training_period, :for_ect) }

      context "when the declaration duplicates an existing declaration" do
        before { FactoryBot.create(:declaration, :payable, training_period:, declaration_type: :started) }

        it "is not valid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:base]).to include("A matching declaration already exists.")
        end
      end

      context "when the declaration does not duplicate an existing declaration" do
        before { FactoryBot.create(:declaration, :voided, training_period:, declaration_type: :completed) }

        it { is_expected.to be_valid }
      end
    end

    describe "uplifts absent for mentor declarations" do
      subject(:declaration) { FactoryBot.build(:declaration, training_period:, sparsity_uplift: true, pupil_premium_uplift: true) }

      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 1.month.ago) }
      let(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on: 1.month.ago) }

      it "is not valid" do
        expect(declaration).to be_invalid
        expect(declaration).to have_one_error_per_attribute
        expect(declaration).to have_error(:sparsity_uplift, "must be absent for mentor declarations.")
        expect(declaration).to have_error(:pupil_premium_uplift, "must be absent for mentor declarations.")
      end
    end
  end

  describe "scopes" do
    describe "payment statuses scopes" do
      let(:declarations) { described_class.payment_statuses.keys.map { |status| FactoryBot.create(:declaration, :"#{status}") } }

      describe ".billable_or_changeable" do
        let(:billable_declarations) { declarations.select { |d| described_class::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES.include?(d.payment_status) } }

        it "returns declarations with billable or changeable payment statuses" do
          expect(described_class.billable_or_changeable).to match_array(billable_declarations)
        end

        Declaration.clawback_statuses.values.excluding("no_clawback").each do |clawback_status|
          context "when clawback_status is `#{clawback_status}`" do
            before do
              billable_declarations.each do |d|
                d.update!(
                  clawback_status:,
                  clawback_statement: FactoryBot.create(:statement, :open, contract_period: d.training_period.contract_period)
                )
              end
            end

            it "returns no declarations" do
              expect(described_class.billable_or_changeable).to be_empty
            end
          end
        end
      end

      describe ".billable_or_changeable_for_declaration_type" do
        let(:billable_or_changeable_declarations) { declarations.select { |d| described_class::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES.include?(d.payment_status) } }

        it "returns declarations with billable or changeable payment statuses for a specific declaration type" do
          declaration = billable_or_changeable_declarations.sample
          declaration.update!(declaration_type: "retained-1")

          expect(described_class.billable_or_changeable_for_declaration_type("retained-1")).to contain_exactly(declaration)
        end

        Declaration.clawback_statuses.values.excluding("no_clawback").each do |clawback_status|
          context "when clawback_status is `#{clawback_status}`" do
            before do
              billable_or_changeable_declarations.each do |d|
                d.update!(
                  clawback_status:,
                  clawback_statement: FactoryBot.create(:statement, :open, contract_period: d.training_period.contract_period)
                )
              end
            end

            it "returns no declarations" do
              expect(described_class.billable_or_changeable_for_declaration_type("retained-1")).to be_empty
            end
          end
        end
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
          completed: "completed",
          "extended-1": "extended-1",
          "extended-2": "extended-2",
          "extended-3": "extended-3",
        })
        .backed_by_column_of_type(:enum)
        .validating(allowing_nil: false)
        .with_prefix
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

  describe "#billable_or_changeable?" do
    context "when clawback_status is `no_clawback`" do
      subject(:declaration) { FactoryBot.build(:declaration, clawback_status: "no_clawback", payment_status:) }

      Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES.each do |status|
        context "when payment_status is `#{status}`" do
          let(:payment_status) { status }

          it { expect(subject.billable_or_changeable?).to be(true) }
        end
      end

      Declaration.payment_statuses.values.excluding(Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES).each do |status|
        context "when payment_status is `#{status}`" do
          let(:payment_status) { status }

          it { expect(subject.billable_or_changeable?).to be(false) }
        end
      end
    end

    Declaration.clawback_statuses.values.excluding("no_clawback").each do |clawback_status|
      context "when clawback_status is `#{clawback_status}`" do
        subject(:declaration) { FactoryBot.build(:declaration, clawback_status:, payment_status: Declaration.payment_statuses.values.sample) }

        it { expect(subject.billable_or_changeable?).to be(false) }
      end
    end
  end

  describe "#overall_status" do
    %i[no_payment eligible payable paid voided ineligible awaiting_clawback clawed_back].each do |status|
      context "when status is `#{status}`" do
        let(:declaration) { FactoryBot.create(:declaration, status) }

        it "returns `#{status}`" do
          expect(declaration.overall_status).to eq(status.to_s)
        end
      end
    end
  end

  describe "#teacher" do
    subject(:teacher) { declaration.teacher }

    let(:declaration) { FactoryBot.create(:declaration) }

    it { is_expected.to eq(declaration.training_period.teacher) }

    context "when training_period is nil" do
      before { declaration.training_period = nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#duplicate_declaration_exists?" do
    let(:training_period) { FactoryBot.create(:training_period, :for_ect) }

    context "when the declaration is not billable/changeable" do
      subject { FactoryBot.build(:declaration, :voided, training_period:, declaration_type: :started) }

      it { is_expected.not_to be_duplicate_declaration_exists }

      context "when an existing declaration of the same type and state exists" do
        before { FactoryBot.create(:declaration, :voided, training_period:, declaration_type: :started) }

        it { is_expected.not_to be_duplicate_declaration_exists }
      end
    end

    context "when the declaration is billable/changeable" do
      subject { FactoryBot.build(:declaration, :payable, training_period:, declaration_type: :started) }

      it { is_expected.not_to be_duplicate_declaration_exists }

      context "when an existing, billable/changeable declaration of the same type exists" do
        before { FactoryBot.create(:declaration, :eligible, training_period:, declaration_type: :started) }

        it { is_expected.to be_duplicate_declaration_exists }
      end

      context "when an existing, billable/changeable declaration of the same type exists for another teacher" do
        before { FactoryBot.create(:declaration, :eligible, declaration_type: :started) }

        it { is_expected.not_to be_duplicate_declaration_exists }
      end

      context "when an existing, billable/changeable declaration of the same type exists for the other teacher type" do
        before { FactoryBot.create(:declaration, :eligible, training_period: other_type_training_period, declaration_type: :started) }

        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: training_period.teacher, started_on: 1.month.ago, finished_on: nil) }
        let(:other_type_training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: 1.month.ago) }

        it { is_expected.not_to be_duplicate_declaration_exists }
      end

      context "when an existing declaration of a different type exists" do
        before { FactoryBot.create(:declaration, :eligible, training_period:, declaration_type: :completed) }

        it { is_expected.not_to be_duplicate_declaration_exists }
      end

      context "when an existing declaration of a non-billable/changeable type exists" do
        before { FactoryBot.create(:declaration, :clawed_back, training_period:, declaration_type: :started) }

        it { is_expected.not_to be_duplicate_declaration_exists }
      end
    end
  end

  describe "#uplift_paid?" do
    subject(:declaration) { FactoryBot.build(:declaration, training_period:, declaration_type:, payment_status:, sparsity_uplift:, pupil_premium_uplift:) }

    let(:training_period) { FactoryBot.build_stubbed(:training_period) }
    let(:declaration_type) { Declaration.declaration_types.values.sample }
    let(:payment_status) { Declaration.payment_statuses.values.sample }
    let(:sparsity_uplift) { [true, false].sample }
    let(:pupil_premium_uplift) { [true, false].sample }

    context "when ECT" do
      before { allow(training_period).to receive(:for_ect?).and_return(true) }

      context "when declaration_type is `started`" do
        let(:declaration_type) { "started" }

        context "when payment_status is `paid`" do
          let(:payment_status) { "paid" }

          [true, false].each do |s_uplift|
            context "when sparsity_uplift is `#{s_uplift}`" do
              [true, false].each do |p_uplift|
                context "when pupil_premium_uplift is `#{p_uplift}`" do
                  let(:sparsity_uplift) { s_uplift }
                  let(:pupil_premium_uplift) { p_uplift }

                  it { expect(declaration.uplift_paid?).to be(s_uplift || p_uplift) }
                end
              end
            end
          end
        end

        context "when payment status is not `paid`" do
          let(:payment_status) { Declaration.payment_statuses.values.excluding("paid").sample }

          it { expect(declaration.uplift_paid?).to be(false) }
        end
      end

      context "when declaration_type is not `started`" do
        let(:declaration_type) { Declaration.declaration_types.values.excluding("started").sample }

        it { expect(declaration.uplift_paid?).to be(false) }
      end
    end

    context "when Mentor" do
      before { allow(training_period).to receive(:for_ect?).and_return(false) }

      it { expect(declaration.uplift_paid?).to be(false) }
    end
  end

  describe "#voidable_payment?" do
    Declaration::VOIDABLE_PAYMENT_STATUSES.each do |status|
      context "when payment_status is `#{status}`" do
        subject(:declaration) do
          FactoryBot.build_stubbed(:declaration, payment_status: status)
        end

        it { is_expected.to be_voidable_payment }
      end
    end

    Declaration.payment_statuses.values.excluding(Declaration::VOIDABLE_PAYMENT_STATUSES).each do |status|
      context "when payment_status is `#{status}`" do
        subject(:declaration) do
          FactoryBot.build_stubbed(:declaration, payment_status: status)
        end

        it { is_expected.not_to be_voidable_payment }
      end
    end
  end

  describe ".milestone" do
    subject { declaration.milestone }

    context "when there is no training_period" do
      let(:declaration) { FactoryBot.build(:declaration, :started, training_period: nil) }

      it { is_expected.to be_nil }
    end

    context "when schedule exists but no milestone for `declaration_type`" do
      let(:training_period) { FactoryBot.create(:training_period) }
      let(:declaration) { FactoryBot.create(:declaration, :started, training_period:) }

      before { FactoryBot.create(:milestone, declaration_type: "retained-1", schedule: training_period.schedule) }

      it { is_expected.to be_nil }
    end

    context "when milestone exists for `declaration_type`" do
      let(:training_period) { FactoryBot.create(:training_period) }
      let!(:milestone) { FactoryBot.create(:milestone, declaration_type: "started", schedule: training_period.schedule) }
      let(:declaration) { FactoryBot.create(:declaration, :started, training_period:, declaration_date: Faker::Date.between(from: milestone.start_date, to: milestone.milestone_date)) }

      it { is_expected.to eq(milestone) }
    end
  end
end
