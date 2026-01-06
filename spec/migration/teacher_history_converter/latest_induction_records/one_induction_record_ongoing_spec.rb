describe "One induction record (ongoing - no end date)" do
  subject(:actual_output) { ecf2_teacher_history.to_h }

  let(:school) { Types::SchoolData.new(name: "School 1", urn: 123_456) }
  let(:lead_provider_a) { { name: "Lead provider A", ecf1_id: "11111111-2222-3333-aaaa-cccccccccccc" } }
  let(:delivery_partner_a) { { name: "DeliveryPartner A", ecf1_id: "11111111-2222-3333-aaaa-dddddddddddd" } }

  let(:input) do
    {
      trn: "1234567",
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records: [
          {
            start_date: Date.new(2024, 1, 2),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year: 2024,
            school: {
              name: school.name,
              urn: school.urn,
            },
            training_provider_info: {
              lead_provider: lead_provider_a,
              delivery_partner: delivery_partner_a,
              cohort_year: 2024
            }
          }
        ]
      },
    }
  end

  let(:expected_output) do
    {
      teacher: hash_including(
        trn: "1234567",
        api_ect_training_record_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        ect_at_school_periods: [
          hash_including(
            started_on: Date.new(2024, 1, 2),
            finished_on: nil,
            school:,
            # training_periods: [
            #   hash_including(
            #     started_on: Date.new(2024, 1, 2),
            #     finished_on: nil,
            #     training_programme: "provider_led",
            #     lead_provider_info: Types::LeadProviderInfo.new(**lead_provider_a),
            #     delivery_partner_info: Types::DeliveryPartnerInfo.new(**delivery_partner_a),
            #     contract_period_year: 2024
            #   )
            # ]
          )
        ]
      ),
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }
  let(:ecf2_teacher_history) { TeacherHistoryConverter.new(ecf1_teacher_history:, migration_mode: :latest_induction_records).convert_to_ecf2! }

  it "produces the expected output" do
    expect(actual_output).to include(expected_output)
  end
end
