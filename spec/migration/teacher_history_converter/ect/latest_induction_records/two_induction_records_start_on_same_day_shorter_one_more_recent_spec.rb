describe "Two induction records start on the same day, the shorter one was created more recently" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  # When there are two induction records and the one which started latest
  # is ongoing.
  #      ┌───────────────────────────────────┐
  #      │                                   │
  #      └───────────────────────────────────┘
  #      ┌────────────────────────┐
  #      │ (created_at later)     │
  #      └────────────────────────┘
  #
  # We want to convert the shorter one into a stub and place it before the
  # longer (more recently created one)
  #
  #      ┌────────────────────────┐
  #      │ (created_at later)     │
  #      └────────────────────────┘
  # ┌────┐
  # │ 🗜️ │
  # └────┘

  let(:cohort_year) { 2024 }

  let(:lead_provider_a) { { name: "Lead provider A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-cccccccccccc" } }
  let(:lead_provider_b) { { name: "Lead provider B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-cccccccccccc" } }

  let(:delivery_partner_a) { { name: "DeliveryPartner A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-dddddddddddd" } }
  let(:delivery_partner_b) { { name: "DeliveryPartner B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-dddddddddddd" } }

  let(:school_a) { { name: "School A", urn: 111_111 } }
  let(:school_b) { { name: "School B", urn: 222_222 } }

  let(:input) do
    {
      trn: "1234567",
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records: [
          {
            start_date: Time.zone.local(2024, 3, 3, 0, 0, 0),
            end_date: Time.zone.local(2024, 9, 9, 0, 0, 0),
            created_at: Time.zone.local(2022, 1, 1, 0, 0, 0),
            school: school_a,
            training_provider_info: {
              lead_provider: lead_provider_a,
              delivery_partner: delivery_partner_a,
              cohort_year:
            }
          },
          {
            start_date: Time.zone.local(2024, 3, 3, 0, 0, 0),
            end_date: Time.zone.local(2024, 7, 7, 0, 0, 0),
            created_at: Time.zone.local(2025, 1, 1, 0, 0, 0),
            school: school_b,
            training_provider_info: {
              lead_provider: lead_provider_b,
              delivery_partner: delivery_partner_b,
              cohort_year:
            }
          }
        ]
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }

  it "produces two ECT at school periods with one training period each" do
    expect(subject.ect_at_school_period_rows.count).to be(2)
  end

  it "creates a 'stub' ECT at school period that lasts 1 day, immediately before the ongoing period", skip: "Implement behaviour" do
    stub_ect_at_school_period = subject.ect_at_school_period_rows[0]

    aggregate_failures do
      expect(stub_ect_at_school_period.started_on).to eql(Date.new(2024, 3, 1))
      expect(stub_ect_at_school_period.finished_on).to eql(Date.new(2024, 3, 2))
    end
  end

  it "creates a finished ECT at school period that starts on the day the ongoing induction record started", skip: "Implement behaviour" do
    finished_ect_at_school_period = subject.ect_at_school_period_rows[1]

    aggregate_failures do
      expect(finished_ect_at_school_period.started_on).to eql(Date.new(2024, 3, 3))
      expect(finished_ect_at_school_period.finished_on).to eql(Date.new(2024, 7, 7))
    end
  end

  it "creates training periods that span the entire ECT at school period"
end
