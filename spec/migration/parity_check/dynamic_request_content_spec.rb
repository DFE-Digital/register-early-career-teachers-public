RSpec.describe ParityCheck::DynamicRequestContent, :with_metadata do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:instance) { described_class.new(lead_provider:) }

  describe "#fetch" do
    subject(:fetch) { instance.fetch(identifier) }

    context "when fetching an unrecognized identifier" do
      let(:identifier) { :unrecognized_identifier }

      it { expect { fetch }.to raise_error(described_class::UnrecognizedIdentifierError, "Identifier not recognized: unrecognized_identifier") }
    end

    context "when fetching statement_id" do
      let(:identifier) { :statement_id }
      let!(:statement) { FactoryBot.create(:statement, :output_fee, lead_provider:) }

      before do
        # Statement for different lead provider should not be used.
        FactoryBot.create(:statement)
        # Statement for service fee should not be used
        FactoryBot.create(:statement, :service_fee, lead_provider:)
      end

      it { is_expected.to eq(statement.api_id) }
    end

    context "when fetching school_id" do
      let(:identifier) { :school_id }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, active_lead_provider:) }
      let!(:school) { FactoryBot.create(:school, :eligible, :not_cip_only) }

      before do
        # Ineligible school
        FactoryBot.create(:school, :ineligible, :not_cip_only)
          .tap { it.gias_school.update!(funding_eligibility: :ineligible) }
        # CIP only school
        FactoryBot.create(:school, :eligible, :cip_only)
      end

      it { is_expected.to eq(school.api_id) }
    end

    context "when fetching delivery_partner_id" do
      let(:identifier) { :delivery_partner_id }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:delivery_partner) { lead_provider_delivery_partnership.delivery_partner }

      before do
        # Delivery partner for different lead provider should not be used.
        FactoryBot.create(:delivery_partner)
      end

      it { is_expected.to eq(delivery_partner.api_id) }
    end

    context "when fetching `partnership_id`" do
      let(:identifier) { :partnership_id }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }

      before do
        # Partnership for different lead provider should not be used.
        FactoryBot.create(:school_partnership)
      end

      it { is_expected.to eq(partnership.api_id) }
    end

    context "when fetching `teacher_api_id`", :with_metadata do
      let(:identifier) { :teacher_api_id }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, active_lead_provider:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:) }
      let(:teacher) { training_period.trainee.teacher }

      before do
        # Participants for different lead providers should not be used.
        FactoryBot.create(:training_period, :for_ect, :ongoing)
        FactoryBot.create(:training_period, :for_mentor, :ongoing)
      end

      it { is_expected.to eq(teacher.api_id) }
    end

    context "when fetching `from_teacher_api_id`", :with_metadata do
      let(:identifier) { :from_teacher_api_id }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, active_lead_provider:) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:) }
      let(:teacher) { training_period.trainee.teacher }
      let(:from_teacher) { FactoryBot.create(:teacher) }

      before do
        # Should return results from this teacher_id_change
        FactoryBot.create(:teacher_id_change, teacher:, api_from_teacher_id: from_teacher.api_id)

        # Participants with teacher_id_change for different lead providers should not be used.
        unused_teacher1 = FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher
        FactoryBot.create(:teacher_id_change, teacher: unused_teacher1)
        unused_teacher2 = FactoryBot.create(:training_period, :for_mentor, :ongoing).trainee.teacher
        FactoryBot.create(:teacher_id_change, teacher: unused_teacher2)
      end

      it { is_expected.to eq(from_teacher.api_id) }
    end

    context "when fetching partnership_create_body" do
      let(:identifier) { :partnership_create_body }
      let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:school) { FactoryBot.create(:school, :eligible, :not_cip_only) }

      before do
        # Disabled contract period
        disabled_contract_period = FactoryBot.create(:contract_period, enabled: false)
        other_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: disabled_contract_period)
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: other_active_lead_provider)
        # Different lead provider
        FactoryBot.create(:lead_provider_delivery_partnership)
        # Ineligible school
        FactoryBot.create(:school, :ineligible)
        # CIP only school
        FactoryBot.create(:school, :eligible, :cip_only)
      end

      it "returns a partnership create body" do
        expect(fetch).to eq({
          data: {
            type: "partnerships",
            attributes: {
              cohort: active_lead_provider.contract_period_year,
              school_id: school.api_id,
              delivery_partner_id: lead_provider_delivery_partnership.delivery_partner.api_id,
            },
          },
        })
      end

      context "when a contract period does not exist" do
        let(:active_lead_provider) {}
        let(:lead_provider_delivery_partnership) {}

        it { expect(fetch).to be_nil }
      end

      context "when a lead provider delivery partnership does not exist" do
        let(:lead_provider_delivery_partnership) {}

        it { expect(fetch).to be_nil }
      end

      context "when a school does not exist" do
        let(:school) {}

        it { expect(fetch).to be_nil }
      end
    end

    context "when fetching partnership_update_body" do
      let(:identifier) { :partnership_update_body }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
      let!(:other_delivery_partner) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:).delivery_partner }

      before do
        # Different lead provider.
        FactoryBot.create(:lead_provider_delivery_partnership)
        # Different contract period.
        other_contract_period = FactoryBot.create(:contract_period, year: active_lead_provider.contract_period_year - 1)
        other_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: other_contract_period)
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: other_active_lead_provider)
      end

      it "returns a partnership update body" do
        expect(fetch).to eq({
          data: {
            type: "partnerships",
            attributes: {
              delivery_partner_id: other_delivery_partner.api_id,
            },
          },
        })
      end

      context "when a school partnership does not exist" do
        let(:school_partnership) {}

        it { expect(fetch).to be_nil }
      end

      context "when another delivery partner does not exist" do
        let(:other_delivery_partner) {}

        it { expect(fetch).to be_nil }
      end
    end

    context "when fetching the same identifier more than once" do
      let(:identifier) { :statement_id }
      let!(:statement) { FactoryBot.create(:statement, :output_fee, lead_provider:) }

      it "memoises the returned value for the same identifier in subsequent calls" do
        expect(API::Statements::Query).to receive(:new).once.and_call_original

        2.times { instance.fetch(identifier) }
      end
    end

    context "when fetching `active_teacher_api_id_for_participant_action`" do
      let(:identifier) { :active_teacher_api_id_for_participant_action }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, active_lead_provider:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:) }
      let(:teacher) { training_period.trainee.teacher }

      before do
        # Deferred participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, :deferred, school_partnership:)
        # Withdrawn participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, :withdrawn, school_partnership:)
        # Participants for different lead providers should not be used
        FactoryBot.create(:training_period, :for_ect, :ongoing)
      end

      it { is_expected.to eq(teacher.api_id) }
    end

    context "when fetching `withdrawn_teacher_api_id_for_participant_action`" do
      let(:identifier) { :withdrawn_teacher_api_id_for_participant_action }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, active_lead_provider:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, :withdrawn, school_partnership:) }
      let(:teacher) { training_period.trainee.teacher }

      before do
        # Active participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:)
        # Deferred participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, :deferred, school_partnership:)
        # Participant for different lead providers should not be used.
        FactoryBot.create(:training_period, :for_ect, :ongoing, :withdrawn)
      end

      it { is_expected.to eq(teacher.api_id) }
    end

    context "when fetching `active_participant_withdraw_body`" do
      let(:identifier) { :active_participant_withdraw_body }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, :withdrawn, school_partnership:) }
      let(:teacher) { training_period.trainee.teacher }

      before do
        # Active participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:)
        # Deferred participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, :deferred, school_partnership:)
        # Mentor participant for current lead provider
        FactoryBot.create(:training_period, :for_mentor, :ongoing, :deferred, school_partnership:)
        # Participant for different lead providers should not be used.
        FactoryBot.create(:training_period, :for_ect, :ongoing, :withdrawn)
        # Stub withdrawal reasons so we have a predictable value
        allow(TrainingPeriod).to receive(:withdrawal_reasons).and_return({ parental_leave: "parental_leave" })
      end

      it "returns a participant withdraw body" do
        expect(fetch).to eq({
          data: {
            type: "participant-withdraw",
            attributes: {
              reason: "parental-leave",
              course_identifier: "ecf-induction"
            },
          },
        })
      end
    end

    context "when fetching `withdrawn_participant_withdraw_body`" do
      let(:identifier) { :withdrawn_participant_withdraw_body }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, :withdrawn, school_partnership:) }
      let(:teacher) { training_period.trainee.teacher }

      before do
        # Active participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:)
        # Deferred participant for current lead provider
        FactoryBot.create(:training_period, :for_ect, :ongoing, :deferred, school_partnership:)
        # Mentor participant for current lead provider
        FactoryBot.create(:training_period, :for_mentor, :ongoing, :deferred, school_partnership:)
        # Participant for different lead providers should not be used.
        FactoryBot.create(:training_period, :for_ect, :ongoing, :withdrawn)
        # Stub withdrawal reasons so we have a predictable value
        allow(TrainingPeriod).to receive(:withdrawal_reasons).and_return({ parental_leave: "parental_leave" })
      end

      it "returns a withdrawn participant withdraw body" do
        expect(fetch).to eq({
          data: {
            type: "participant-withdraw",
            attributes: {
              reason: "parental-leave",
              course_identifier: "ecf-induction"
            },
          },
        })
      end
    end
  end
end
