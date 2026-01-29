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
      ect: {
        participant_profile_id: "11111111-2222-3333-aaaa-bbbbbbbbbbbb",
        induction_records:
      }
    }
  end

  let!(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }

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
      #  To these ECT at school periods:
      #                                        ┌───┐
      #                                        │ A │
      #                                        └───┘
      #                                             ┌───────────────┐
      #                                             │       B       │
      #                                             └───────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-3-3", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-5-5" },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-5-5" },
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
      #  To these ECT at school periods:
      #                                        ┌───┐
      #                                        │ A │
      #                                        └───┘
      #                                             ┌───────────────┐
      #                                             │       B       │
      #                                             └───────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-3-3", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-6-6" },
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
      #  To these ECT at school periods:
      #                            ┌───────────────┐┌─────────┐
      #                            │       B       ││   ✂️    │
      #                            └───────────────┘└─────────┘
      #                                             ┌────────────────────┐
      #                                             │         A          │
      #                                             └────────────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-4-4", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-5-5" },
      ],
      at_school_periods: [
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-4-3" },
        { urn: 111_111, started_on: "2024-4-4", finished_on: "2024-6-6" },
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
      #  To these ECT at school periods:
      #           ┌────────────────────┐
      #           │         B          │
      #           └────────────────────┘
      #                                     ┌────────────────────┐
      #                                     │        A           │
      #                                     └────────────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-5-5", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-4-4" },
      ],
      at_school_periods: [
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-4-4" },
        { urn: 111_111, started_on: "2024-5-5", finished_on: "2024-6-6" },
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
      #  To these ECT at school periods:
      #      ┌───┐
      #      │ A │
      #      └───┘
      #           ┌────────────────────┐
      #           │         B          │
      #           └────────────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-3-3", end_date: "2024-5-5" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-6-6" },
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
      #  To these ECT at school periods:
      #           ┌──────────┐┌───────────────────────────┐
      #           │     A    ││             ✂️            │
      #           └──────────┘└───────────────────────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-1-1", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-5-5" },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-5-5" },
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
      #  To these ECT at school periods:
      #           ┌──────────┐┌────────────────────┐
      #           │     A    ││         ✂️         │
      #           └──────────┘└────────────────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-1-1", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-6-6" },
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
      #  To these ECT at school periods:
      #           ┌──────────┐┌──────────┐
      #           │     A    ││    ✂️    │
      #           └──────────┘└──────────┘
      #                       ┌────────────────────┐
      #                       │         B          │
      #                       └────────────────────┘
      induction_records: [
        { urn: 111_111, start_date: "2024-1-1", end_date: "2024-5-5" },
        { urn: 222_222, start_date: "2024-3-3", end_date: "2024-6-6" },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: "2024-6-6" },
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
      #  To these ECT at school periods:
      #           ┌──────────┐┌──────────┐
      #           │     A    ││    ✂️    │
      #           └──────────┘└──────────┘
      #                       ┌────────────────────>
      #                       │         B
      #                       └────────────────────>
      induction_records: [
        { urn: 111_111, start_date: "2024-1-1", end_date: "2024-5-5" },
        { urn: 222_222, start_date: "2024-3-3", end_date: :ignore },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-1-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: nil },
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
      #  To these ECT at school periods:
      #      ┌───┐
      #      │ A │
      #      └───┘
      #           ┌────────────────────────────>
      #           │           B
      #           └────────────────────────────>
      induction_records: [
        { urn: 111_111, start_date: "2024-3-3", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: :ignore },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: nil },
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
      #  To these ECT at school periods:
      #      ┌───┐
      #      │ A │
      #      └───┘
      #           ┌────────────────────────────────────>
      #           │                 B
      #           └────────────────────────────────────>
      induction_records: [
        { urn: 111_111, start_date: "2024-4-4", end_date: "2024-6-6" },
        { urn: 222_222, start_date: "2024-3-3", end_date: :ignore },
      ],
      at_school_periods: [
        { urn: 111_111, started_on: "2024-3-1", finished_on: "2024-3-2" },
        { urn: 222_222, started_on: "2024-3-3", finished_on: nil },
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

      it "creates the right expected number of ECT at school periods" do
        expect(subject.ect_at_school_periods.size).to eq(data[:at_school_periods].size)
      end

      it "produces the expected ECT at school periods" do
        aggregate_failures do
          data[:at_school_periods].each_with_index do |at_school_period, i|
            started_on = Date.parse(at_school_period[:started_on])
            finished_on = Date.parse(at_school_period[:finished_on]) if at_school_period[:finished_on].present?

            expect(subject.ect_at_school_periods[i].started_on).to eql(started_on)
            expect(subject.ect_at_school_periods[i].finished_on).to eql(finished_on)
            expect(subject.ect_at_school_periods[i].school.urn).to eql(at_school_period[:urn])
          end
        end
      end

      it "creates training periods that span the entire ECT at school period" do
        aggregate_failures do
          subject.ect_at_school_periods.each do |school_period|
            expect(school_period.started_on).to eq school_period.training_periods.first.started_on
            expect(school_period.finished_on).to eq school_period.training_periods.first.finished_on
          end
        end
      end
    end
  end

  context "mentorship periods" do
    let!(:school_222_222) { FactoryBot.create(:school, urn: 222_222) }
    let(:mentor_profile_id) { SecureRandom.uuid }
    let(:mentor_teacher) { FactoryBot.create(:teacher, :with_name, api_mentor_training_record_id: mentor_profile_id) }

    let(:induction_records) do
      [
        {
          start_date: Time.zone.parse("2024-1-1"),
          end_date: Time.zone.parse("2024-5-5"),
          school: school_a,
          training_provider_info: {
            lead_provider: lead_provider_a,
            delivery_partner: delivery_partner_a,
            cohort_year:
          }
        },
        {
          start_date: Time.zone.parse("2024-3-3"),
          end_date: Time.zone.parse("2024-6-6"),
          school: school_b,
          mentor_profile_id:,
          training_provider_info: {
            lead_provider: lead_provider_a,
            delivery_partner: delivery_partner_a,
            cohort_year:
          }
        }
      ]
    end

    context "when there is no mentor at school period overlaping the last starting ect_at_school_period" do
      before do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: mentor_teacher,
                          school: school_222_222,
                          start_date: Date.parse("2024-1-1"),
                          end_date: Date.parse("2024-2-2"))
      end

      it "don't create any mentorship at school period" do
        expect(subject.ect_at_school_periods.last.mentorship_periods).to be_empty
      end
    end

    context "when there is a mentor at school period overlaping only the start of the last starting ect_at_school_period" do
      before do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: mentor_teacher,
                          school: school_222_222,
                          start_date: Date.parse("2024-1-1"),
                          end_date: Date.parse("2024-2-2"))

        FactoryBot.create(:mentor_at_school_period,
                          teacher: mentor_teacher,
                          school: school_222_222,
                          start_date: Date.parse("2024-2-15"),
                          end_date: Date.parse("2024-4-4"))
      end

      it "create a mentorship at school period with the overlapped range of dates" do
        expect(subject.ect_at_school_periods.last.mentorship_periods.size).to eq(1)
        expect(subject.ect_at_school_periods.last.mentorship_periods.first.started_on).to eq(Date.parse("2024-3-3"))
        expect(subject.ect_at_school_periods.last.mentorship_periods.first.finished_on).to eq(Date.parse("2024-4-4"))
      end
    end

    context "when there is a mentor at school period overlaping only the end of the last starting ect_at_school_period" do
      before do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: mentor_teacher,
                          school: school_222_222,
                          start_date: Date.parse("2024-1-1"),
                          end_date: Date.parse("2024-4-4"))

        FactoryBot.create(:mentor_at_school_period,
                          teacher: mentor_teacher,
                          school: school_222_222,
                          start_date: Date.parse("2024-5-5"),
                          end_date: nil)
      end

      it "create a mentorship at school period with the overlapped range of dates" do
        expect(subject.ect_at_school_periods.last.mentorship_periods.size).to eq(1)
        expect(subject.ect_at_school_periods.last.mentorship_periods.first.started_on).to eq(Date.parse("2024-5-5"))
        expect(subject.ect_at_school_periods.last.mentorship_periods.first.finished_on).to eq(Date.parse("2024-6-6"))
      end
    end

    context "when there is a mentor at school period containing the last starting ect_at_school_period" do
      before do
        FactoryBot.create(:mentor_at_school_period,
                          teacher: mentor_teacher,
                          school: school_222_222,
                          start_date: Date.parse("2024-1-1"),
                          end_date: Date.parse("2024-2-2"))

        FactoryBot.create(:mentor_at_school_period,
                          teacher: mentor_teacher,
                          school: school_222_222,
                          start_date: Date.parse("2024-2-15"),
                          end_date: nil)
      end

      it "create a mentorship at school period with the overlapped range of dates" do
        expect(subject.ect_at_school_periods.last.mentorship_periods.size).to eq(1)
        expect(subject.ect_at_school_periods.last.mentorship_periods.first.started_on).to eq(Date.parse("2024-3-3"))
        expect(subject.ect_at_school_periods.last.mentorship_periods.first.finished_on).to eq(Date.parse("2024-6-6"))
      end
    end
  end

  context "training period details" do
    let(:schedule_a) do
      {
        schedule_id: 1,
        identifier: "ect-schedule-a",
        name: "Schedule A",
        cohort_year: 2021,
      }
    end

    let(:schedule_b) do
      {
        schedule_id: 2,
        identifier: "ect-schedule-b",
        name: "Schedule B",
        cohort_year: 2024,
      }
    end

    let(:induction_records) do
      [
        {
          start_date: Time.zone.parse("2022-1-1"),
          end_date: Time.zone.parse("2022-8-5"),
          school: school_a,
          training_programme:,
          training_provider_info: {
            lead_provider: lead_provider_a,
            delivery_partner: delivery_partner_a,
            cohort_year: 2021
          },
          schedule_info: schedule_a
        },
        {
          start_date: Time.zone.parse("2024-3-3"),
          end_date: Time.zone.parse("2025-6-6"),
          school: school_b,
          training_programme:,
          training_provider_info: {
            lead_provider: lead_provider_b,
            delivery_partner: delivery_partner_b,
            cohort_year: 2024
          },
          schedule_info: schedule_b
        }
      ]
    end

    context "provider_led training" do
      let(:training_programme) { "full_induction_programme" }

      it "adds the correct providers to the training period" do
        expect(subject.ect_at_school_periods.first.training_periods.first.lead_provider_info.name).to eq lead_provider_a[:name]
        expect(subject.ect_at_school_periods.first.training_periods.first.delivery_partner_info.name).to eq delivery_partner_a[:name]

        expect(subject.ect_at_school_periods.second.training_periods.first.lead_provider_info.name).to eq lead_provider_b[:name]
        expect(subject.ect_at_school_periods.second.training_periods.first.delivery_partner_info.name).to eq delivery_partner_b[:name]
      end

      it "adds the correct schedule to the training period" do
        schedule_2021 = subject.ect_at_school_periods.first.training_periods.first.schedule_info
        expect(schedule_2021.name).to eq schedule_a[:name]
        expect(schedule_2021.cohort_year).to eq schedule_a[:cohort_year]

        schedule_2024 = subject.ect_at_school_periods.second.training_periods.first.schedule_info
        expect(schedule_2024.name).to eq schedule_b[:name]
        expect(schedule_2024.cohort_year).to eq schedule_b[:cohort_year]
      end
    end

    context "school_led training" do
      let(:training_programme) { "core_induction_programme" }

      it "does not add providers to the training period" do
        expect(subject.ect_at_school_periods.first.training_periods.first.lead_provider_info).to be_blank
        expect(subject.ect_at_school_periods.first.training_periods.first.delivery_partner_info).to be_blank

        expect(subject.ect_at_school_periods.second.training_periods.first.lead_provider_info).to be_blank
        expect(subject.ect_at_school_periods.second.training_periods.first.delivery_partner_info).to be_blank
      end

      it "does not add a schedule to the training period" do
        expect(subject.ect_at_school_periods.first.training_periods.first.schedule_info).to be_blank
        expect(subject.ect_at_school_periods.second.training_periods.first.schedule_info).to be_blank
      end
    end
  end
end
