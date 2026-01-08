describe "Trim period to make way for next" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  # Scenario 5
  #
  # When there are two induction records with different lead providers
  # that start sequentially and overlap, we trim the start of the later
  # one.
  #
  # ┌──────────────────────┐
  # │                      │
  # └──────────────────────┘
  #                   ┌────┐─────────────────┐
  #                   │ ✂️ │                 │
  #                   └────┘─────────────────┘

  let(:cohort_year) { 2024 }
  let(:lead_provider_a) { { name: "Lead provider A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-cccccccccccc" } }
  let(:delivery_partner_a) { { name: "DeliveryPartner A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-dddddddddddd" } }
  let(:lead_provider_b) { { name: "Lead provider B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-cccccccccccc" } }

  let(:input) do
    {
      trn: "1234567",
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records: [
          {
            start_date: Date.new(2024, 1, 1),
            end_date: Date.new(2024, 5, 5),
            training_provider_info: {
              lead_provider: lead_provider_a,
              delivery_partner: delivery_partner_a,
              cohort_year:
            }
          },
          {
            start_date: Date.new(2024, 5, 1),
            end_date: Date.new(2024, 8, 1),
            training_provider_info: {
              lead_provider: lead_provider_b,
              delivery_partner: delivery_partner_a,
              cohort_year:
            }
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }

  it "produces two ECT at school periods" do
    expect(subject.ect_at_school_period_rows.count).to be(2)
  end

  it "starts and finishes the first one with the dates from the first induction record"
  it "starts the second one when the first finishes and leaves its original end date intact"
end
