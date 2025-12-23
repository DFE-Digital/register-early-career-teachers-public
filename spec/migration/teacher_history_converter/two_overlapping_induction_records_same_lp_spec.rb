describe "Two overlapping..." do
  let(:input) do
    {
      trn: "1234567",
      ect: {
        induction_records: [
          {
            start_date: Date.new(2024, 1, 1),
            end_date: Date.new(2024, 2, 2),
            training_programme: "full_induction_programme",
            cohort_year:,
            school_urn: "123456",
            training_provider_info: {
              lead_provider_info: lead_provider_a,
              delivery_partner_info: delivery_partner_a,
              cohort_year:
            }
          },
          {
            start_date: Date.new(2024, 1, 15),
            end_date: :ignore,
            training_programme: "full_induction_programme",
            cohort_year:,
            school_urn: "123456",
            training_provider_info: {
              lead_provider_info: lead_provider_a,
              delivery_partner_info: delivery_partner_a,
              cohort_year:
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
            started_on: Date.new(2024, 1, 1),
            finished_on: nil,
            # TODO: school
            training_periods: [
              hash_including(
                started_on: Date.new(2024, 1, 1),
                finished_on: nil,
                training_programme: "provider_led",
                lead_provider_info: lead_provider_a,
                delivery_partner_info: delivery_partner_a,
                contract_period_year: 2024
              )
            ]
          )
        ]
      ),
    }
  end
end
