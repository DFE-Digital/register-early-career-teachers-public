describe "Earlier created induction record contains next one" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  # When there are two induction records and the earlier starting one
  # contains the later starting one
  #
  #   ┌──────────────────────────────────────┐
  #   │                                      │
  #   └──────────────────────────────────────┘
  #                   ┌──────────────┐
  #                   │              │
  #                   └──────────────┘
  #
  # We want to create a 'stub' mentor at school period that lasts for one
  # day, immediately before the original earlier one starts
  #
  #   ┌───────────────┐──────────────────────┐
  #   │               │         ✂️           │
  #   └───────────────┘──────────────────────┘
  #                   ┌──────────────┐
  #                   │              │
  #                   └──────────────┘

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
      mentor: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records: [
          {
            start_date: Time.zone.local(2024, 3, 3, 0, 0, 0),
            end_date: Time.zone.local(2024, 6, 6, 0, 0, 0),
            school: school_a,
            training_provider_info: {
              lead_provider: lead_provider_a,
              delivery_partner: delivery_partner_a,
              cohort_year:
            }
          },
          {
            start_date: Time.zone.local(2024, 4, 4, 0, 0, 0),
            end_date: Time.zone.local(2024, 5, 5, 0, 0, 0),
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

  it "produces two mentor at school periods" do
    expect(subject.mentor_at_school_period_rows.count).to be(2)
  end

  it "creates a 'stub' mentor at school period that lasts 1 day, immediately before the ongoing period" do
    stub_mentor_at_school_period = subject.mentor_at_school_period_rows[0]

    aggregate_failures do
      expect(stub_mentor_at_school_period.started_on).to eql(Date.new(2024, 3, 3))
      expect(stub_mentor_at_school_period.finished_on).to eql(Date.new(2024, 4, 3))
    end
  end

  it "creates an ongoing mentor at school period that starts on the day the ongoing induction record started" do
    ongoing_mentor_at_school_period = subject.mentor_at_school_period_rows[1]

    aggregate_failures do
      expect(ongoing_mentor_at_school_period.started_on).to eql(Date.new(2024, 4, 4))
      expect(ongoing_mentor_at_school_period.finished_on).to eql(Date.new(2024, 5, 5))
    end
  end

  it "creates training periods that span the entire mentor at school period" do
    subject.mentor_at_school_period_rows.each do |school_period|
      expect(school_period.started_on).to eq school_period.training_period_rows.first.started_on
      expect(school_period.finished_on).to eq school_period.training_period_rows.first.finished_on
    end
  end
end
