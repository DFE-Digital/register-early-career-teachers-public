describe TeacherHistoryConverter::DeferralData do
  subject { TeacherHistoryConverter::DeferralData.new(training_status:, states:, lead_provider_id:).deferral_data }

  let(:bpn_id) { "da470c27-05a6-4f5b-b9a9-58b04bfcc408" }
  let(:edt_id) { "9f0a1bdd-b9af-4603-abfd-c1af01aded76" }
  let(:capita_id) { "7a6753ef-6bb1-4fb3-ba93-fcbf3b20541b" }

  let(:edt_cpd_lead_provider_id) { "af89cf02-bbe0-423b-b2f6-bb2dbb97d141" }
  let(:bpn_cpd_lead_provider_id) { "dfad2a9c-527d-4d71-ae9a-492ab307e6c3" }

  let(:active) do
    ECF1TeacherHistory::ProfileState.new(
      state: "active",
      created_at: 1.minute.ago.round,
      reason: nil,
      cpd_lead_provider_id: edt_cpd_lead_provider_id
    )
  end

  let(:bpn_deferred_1) do
    ECF1TeacherHistory::ProfileState.new(
      state: "deferred",
      created_at: 1.year.ago.round,
      reason: "parental-leave",
      cpd_lead_provider_id: bpn_cpd_lead_provider_id
    )
  end

  let(:bpn_deferred_2) do
    ECF1TeacherHistory::ProfileState.new(
      state: "deferred",
      created_at: 2.years.ago.round,
      reason: "other",
      cpd_lead_provider_id: bpn_cpd_lead_provider_id
    )
  end

  let(:edt_reason) { "other" }

  let(:edt_deferred_1) do
    ECF1TeacherHistory::ProfileState.new(
      state: "deferred",
      created_at: 3.years.ago.round,
      reason: edt_reason,
      cpd_lead_provider_id: edt_cpd_lead_provider_id
    )
  end

  let(:states) { [active, bpn_deferred_2, bpn_deferred_1, edt_deferred_1] }

  context "when training status isn't 'deferred'" do
    let(:training_status) { "active" }
    let(:lead_provider_id) { nil }

    it "returns an empty hash" do
      expect(subject).to eql({})
    end
  end

  context "when training status is 'deferred'" do
    let(:training_status) { "deferred" }

    context "for a lead provider with 2 deferral states" do
      let(:lead_provider_id) { bpn_id }

      it "returns the latest deferral" do
        expect(subject).to eql({ deferral_reason: "parental_leave", deferred_at: 1.year.ago.round })
      end
    end

    context "for a lead provider with 1 deferral state and 1 non-deferral state" do
      let(:lead_provider_id) { edt_id }

      it "returns the only deferral state" do
        expect(subject).to eql({ deferral_reason: "other", deferred_at: 3.years.ago.round })
      end
    end

    context "for a lead provider with 0 states" do
      let(:lead_provider_id) { capita_id }

      it "returns an empty hash" do
        expect(subject).to eql({})
      end
    end

    describe "reason mappings" do
      let(:lead_provider_id) { edt_id }

      {
        "bereavement" => "bereavement",
        "career-break" => "career_break",
        "long-term-sickness" => "long_term_sickness",
        "parental-leave" => "parental_leave",
        "other" => "other",
        "any-other-value" => "other",
        nil => "other",
      }.each do |ecf1_value, ecf2_value|
        context "when the reason in ECF1 is #{ecf1_value || 'nil'}" do
          let(:edt_reason) { ecf1_value }

          it "returns #{ecf2_value}" do
            expect(subject).to eql({ deferral_reason: ecf2_value, deferred_at: 3.years.ago.round })
          end
        end
      end
    end
  end
end
