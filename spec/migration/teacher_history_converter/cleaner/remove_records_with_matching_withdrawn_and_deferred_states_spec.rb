describe TeacherHistoryConverter::Cleaner::RemoveRecordsWithMatchingWithdrawnAndDeferredStates do
  subject(:cleaner) { described_class.new(raw_induction_records, states:) }

  describe "#induction_records" do
    let(:participant_type) { :ect }

    let(:cpd_lead_provider_id) { SecureRandom.uuid }
    let(:lead_provider_id) { training_provider_info.lead_provider_info.ecf1_id }
    let(:training_provider_info) { induction_record_1.training_provider_info }
    let(:state_1) do
      FactoryBot.build(:ecf1_teacher_history_profile_state_row,
                       state: "active",
                       cpd_lead_provider_id:,
                       created_at: induction_record_1.created_at)
    end
    let(:state_2) do
      FactoryBot.build(:ecf1_teacher_history_profile_state_row,
                       state: "active",
                       created_at: induction_record_2.created_at)
    end
    let(:state_3) do
      FactoryBot.build(:ecf1_teacher_history_profile_state_row,
                       state: "active",
                       cpd_lead_provider_id:,
                       created_at: induction_record_3.created_at)
    end
    let(:states) { [state_1, state_2, state_3] }
    let(:training_status) { "active" }
    let(:induction_record_1) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2021, 9, 1),
        end_date: Date.new(2022, 3, 15),
        created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
      )
    end
    let(:induction_record_2) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 3, 15),
        end_date: Date.new(2023, 9, 1),
        created_at: Time.zone.local(2023, 3, 15, 14, 0, 0)
      )
    end
    let(:induction_record_3) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 5, 1),
        end_date: Date.new(2022, 3, 15),
        created_at: Time.zone.local(2022, 5, 1, 12, 0, 0),
        training_status:,
        training_provider_info:
      )
    end
    let(:raw_induction_records) { [induction_record_1, induction_record_2, induction_record_3] }

    before do
      result = instance_double(Mappers::LeadProviderMapper::Result)
      mapper = instance_double(Mappers::LeadProviderMapper)
      allow(Mappers::LeadProviderMapper).to receive(:new).and_return(mapper)
      allow(mapper).to receive(:get).with(cpd_lead_provider_id).and_return(result)
      allow(result).to receive(:id).and_return(lead_provider_id)
    end

    it "returns all the induction records" do
      expect(cleaner.induction_records).to match raw_induction_records
    end

    %w[withdrawn deferred].each do |state|
      context "when there is a #{state} state" do
        let(:state_created_at) { induction_record_3.created_at }

        let(:state_3) do
          FactoryBot.build(:ecf1_teacher_history_profile_state_row,
                           state:,
                           cpd_lead_provider_id:,
                           created_at: state_created_at)
        end

        context "when there are no matching induction records for the #{state} state" do
          it "returns all the induction records" do
            expect(cleaner.induction_records).to match raw_induction_records
          end
        end

        context "when there is a #{state} induction record for the same provider created the same day" do
          let(:training_status) { state }

          it "does not return the matching induction record" do
            expect(cleaner.induction_records).not_to include(induction_record_3)
          end

          it "returns the non-matching induction records" do
            expect(cleaner.induction_records).to match([induction_record_1, induction_record_2])
          end
        end

        context "when there is a #{state} induction record for a different provider" do
          let(:induction_record_3) do
            FactoryBot.build(
              :ecf1_teacher_history_induction_record_row,
              start_date: Date.new(2022, 5, 1),
              end_date: Date.new(2022, 3, 15),
              created_at: Time.zone.local(2022, 5, 1, 12, 0, 0),
              training_status: state
            )
          end

          it "does not remove the induction record" do
            expect(cleaner.induction_records).to match raw_induction_records
          end
        end

        context "when there is a #{state} induction record for the same provider created on a different day" do
          let(:training_status) { state }
          let(:state_created_at) { 1.month.ago }

          it "does not remove the induction record" do
            expect(cleaner.induction_records).to match raw_induction_records
          end
        end

        context "when there is an induction record that matches the '#{state}' state created date and provider, but it is ongoing" do
          let(:induction_record_3) do
            FactoryBot.build(
              :ecf1_teacher_history_induction_record_row,
              start_date: Date.new(2022, 5, 1),
              end_date: nil,
              created_at: Time.zone.local(2022, 5, 1, 12, 0, 0),
              training_status: state,
              training_provider_info:
            )
          end

          it "does not remove the induction record" do
            expect(cleaner.induction_records).to match raw_induction_records
          end
        end
      end
    end
  end
end
