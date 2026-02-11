describe "Latest induction records mode conversion" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

  let(:cohort_year) { 2024 }

  let(:lead_provider_a) { { name: "Lead provider A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-cccccccccccc" } }
  let(:lead_provider_b) { { name: "Lead provider B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-cccccccccccc" } }

  let(:delivery_partner_a) { { name: "DeliveryPartner A", ecf1_id: "aaaaaaaa-2222-3333-aaaa-dddddddddddd" } }
  let(:delivery_partner_b) { { name: "DeliveryPartner B", ecf1_id: "bbbbbbbb-2222-3333-aaaa-dddddddddddd" } }

  let(:school_a) { { name: "School A", urn: 111_111 } }
  let(:school_b) { { name: "School B", urn: 222_222 } }
  let(:schools) { [school_a, school_b] }

  let(:input) do
    {
      trn: "1234567",
      mentor: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records:
      }
    }
  end

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }

  {
    "two IRs share start date. The first ends later than the second" => {
      #  From these induction records:
      #                                             ┌───────────────────────┐
      #                                             │         A             │
      #                                             └───────────────────────┘
      #                                             ┌───────────────┐
      #                                             │       B       │
      #                                             └───────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #                                        ┌───┐
      #                                        │ A │
      #                                        └───┘
      #                                             ┌───────────────┐
      #                                             │       B       │
      #                                             └───────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-3-3", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-5-5" },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-5-5" },
      ]
    },

    "two IRs share start date and end_date" => {
      #  From these induction records:
      #                                             ┌──────────────┐
      #                                             │       A      │
      #                                             └──────────────┘
      #                                             ┌──────────────┐
      #                                             │       B      │
      #                                             └──────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #                                        ┌───┐
      #                                        │ A │
      #                                        └───┘
      #                                             ┌───────────────┐
      #                                             │       B       │
      #                                             └───────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-3-3", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-6-6" },
      ]
    },

    "two IRs. The second one starts before the first one starts and ends before the first one ends" => {
      #  From these induction records:
      #                                             ┌────────────────────┐
      #                                             │        A           │
      #                                             └────────────────────┘
      #                            ┌──────────────────────────┐
      #                            │            B             │
      #                            └──────────────────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #                            ┌───────────────┐┌─────────┐
      #                            │       B       ││   ✂️    │
      #                            └───────────────┘└─────────┘
      #                                             ┌────────────────────┐
      #                                             │         A          │
      #                                             └────────────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-4-4", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-5-5" },
      ],
      at_school_periods: [
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-4-3" },
        { urn: 111_111,  started_on: "2024-4-4", finished_on: "2024-6-6" },
      ]
    },

    "two IRs. The second one starts and ends before the first one starts" => {
      #  From these induction records:
      #                                     ┌────────────────────┐
      #                                     │        A           │
      #                                     └────────────────────┘
      #           ┌────────────────────┐
      #           │         B          │
      #           └────────────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #           ┌────────────────────┐
      #           │         B          │
      #           └────────────────────┘
      #                                     ┌────────────────────┐
      #                                     │        A           │
      #                                     └────────────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-5-5", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-4-4" },
      ],
      at_school_periods: [
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-4-4" },
        { urn: 111_111,  started_on: "2024-5-5", finished_on: "2024-6-6" },
      ]
    },

    "two IRs share start date. The second ends later than the first one" => {
      #  From these induction records:
      #           ┌─────────────────┐
      #           │        A        │
      #           └─────────────────┘
      #           ┌────────────────────┐
      #           │         B          │
      #           └────────────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #      ┌───┐
      #      │ A │
      #      └───┘
      #           ┌────────────────────┐
      #           │         B          │
      #           └────────────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-3-3", end_date: "2024-5-5" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-6-6" },
      ]
    },

    "two IRs. The second starts later and ends earlier than the first one" => {
      #  From these induction records:
      #           ┌───────────────────────────────────────┐
      #           │                     A                 │
      #           └───────────────────────────────────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #           ┌──────────┐┌───────────────────────────┐
      #           │     A    ││             ✂️            │
      #           └──────────┘└───────────────────────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-1-1", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-5-5" },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-5-5" },
      ]
    },

    "two IRs. The second starts later and ends the same day the first one does" => {
      #  From these induction records:
      #           ┌────────────────────────────────┐
      #           │                A               │
      #           └────────────────────────────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #           ┌──────────┐┌────────────────────┐
      #           │     A    ││         ✂️         │
      #           └──────────┘└────────────────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-1-1", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-6-6" },
      ]
    },

    "two IRs. The second starts and ends later than the first one" => {
      #  From these induction records:
      #           ┌──────────────────────┐
      #           │           A          │
      #           └──────────────────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #           ┌──────────┐┌──────────┐
      #           │     A    ││    ✂️    │
      #           └──────────┘└──────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      induction_records: [
        { urn: 111_111,  start_date: "2024-1-1", end_date: "2024-5-5" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: "2024-6-6" },
      ]
    },

    "two IRs. The second starts later than the first one and never ends" => {
      #  From these induction records:
      #           ┌──────────────────────┐
      #           │           A          │
      #           └──────────────────────┘
      #                       ┌────────────────────>
      #                       │         B
      #                       └────────────────────>
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #           ┌──────────┐┌──────────┐
      #           │     A    ││    ✂️    │
      #           └──────────┘└──────────┘
      #                       ┌────────────────────>
      #                       │         B
      #                       └────────────────────>
      induction_records: [
        { urn: 111_111,  start_date: "2024-1-1", end_date: "2024-5-5" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: :ignore },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: nil },
      ]
    },

    "two IRs starts the same day. The second one never ends" => {
      #  From these induction records:
      #           ┌──────────────────────┐
      #           │           A          │
      #           └──────────────────────┘
      #           ┌────────────────────────────>
      #           │             B
      #           └────────────────────────────>
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #      ┌───┐
      #      │ A │
      #      └───┘
      #           ┌────────────────────────────>
      #           │           B
      #           └────────────────────────────>
      induction_records: [
        { urn: 111_111,  start_date: "2024-3-3", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: :ignore },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: nil },
      ]
    },

    "two IRs. The first starts later than the second one. The second one never ends" => {
      #  From these induction records:
      #                 ┌──────────────────────┐
      #                 │           A          │
      #                 └──────────────────────┘
      #           ┌────────────────────────────────────>
      #           │                 B
      #           └────────────────────────────────────>
      # ------------------------------------------------------------------------------------------
      #  To these mentor at school periods:
      #      ┌───┐
      #      │ A │
      #      └───┘
      #           ┌────────────────────────────────────>
      #           │                 B
      #           └────────────────────────────────────>
      induction_records: [
        { urn: 111_111,  start_date: "2024-4-4", end_date: "2024-6-6" },
        { urn: 222_222,  start_date: "2024-3-3", end_date: :ignore },
      ],
      at_school_periods: [
        { urn: 111_111,  started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222,  started_on: "2024-3-3", finished_on: nil },
      ]
    }
  }.each do |description, data|
    context description do
      let(:induction_records) do
        data[:induction_records].map do |induction_record|
          {
            start_date: Time.zone.parse(induction_record[:start_date]),
            end_date: (induction_record[:end_date] == :ignore ? :ignore : Time.zone.parse(induction_record[:end_date])),
            school: schools.find { |school| school[:urn] == induction_record[:urn] },
            training_provider_info: {
              lead_provider: lead_provider_a,
              delivery_partner: delivery_partner_a,
              cohort_year:
            }
          }
        end
      end

      it "creates the right expected number of mentor at school periods" do
        expect(subject.mentor_at_school_periods.size).to eq(data[:at_school_periods].size)
      end

      it "produces the expected mentor at school periods" do
        aggregate_failures do
          data[:at_school_periods].each_with_index do |at_school_period, i|
            started_on = Date.parse(at_school_period[:started_on])
            finished_on = Date.parse(at_school_period[:finished_on]) if at_school_period[:finished_on].present?

            expect(subject.mentor_at_school_periods[i].started_on).to eql(started_on)
            expect(subject.mentor_at_school_periods[i].finished_on).to eql(finished_on)
            expect(subject.mentor_at_school_periods[i].school.urn).to eql(at_school_period[:urn])
          end
        end
      end

      it "creates training periods that span the entire mentor at school period" do
        aggregate_failures do
          subject.mentor_at_school_periods.each do |school_period|
            expect(school_period.started_on).to eq school_period.training_periods.first.started_on
            expect(school_period.finished_on).to eq school_period.training_periods.first.finished_on
          end
        end
      end

      it "create the expected school-lp-cohort combinations" do
        aggregate_failures do
          subject.mentor_at_school_periods.flat_map(&:training_periods).each do |training_period|
            expected_summary = [training_period.school.urn, training_period.contract_period_year, training_period.lead_provider_info&.name].join(": ")
            expect(training_period.combination.summary[39..-2]).to eq(expected_summary)
          end
        end
      end
    end
  end
end
