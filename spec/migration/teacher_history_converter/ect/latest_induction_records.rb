describe "Latest induction records mode conversion" do
  subject { TeacherHistoryConverter.new(ecf1_teacher_history:).convert_to_ecf2! }

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

  let(:ecf1_teacher_history) { ECF1TeacherHistory.from_hash(input) }

  {
    "two IRs share start date. The first ends later than the second" => {
      induction_records: %w[
        2024-3-3..2024-6-6___111_111
        2024-3-3..2024-5-5___222_222
      ],
      at_school_periods: %w[
        2024-3-1..2024-3-2___111_111
        2024-3-3..2024-5-5___222_222
      ]
    },
    "two IRs share start date and end_date" => {
      induction_records: %w[
        2024-3-3..2024-6-6___111_111
        2024-3-3..2024-6-6___222_222
      ],
      at_school_periods: %w[
        2024-3-1..2024-3-2___111_111
        2024-3-3..2024-6-6___222_222
      ]
    },
    "two IRs. The second one starts and end before first one starts" => {
      induction_records: %w[
        2024-4-4..2024-6-6___111_111
        2024-3-3..2024-5-5___222_222
      ],
      at_school_periods: %w[
        2024-3-1..2024-3-2___111_111
        2024-3-3..2024-5-5___222_222
      ]
    },
    "two IRs. The second one starts and end before first one starts" => {
      induction_records: %w[
        2024-5-5..2024-6-6___111_111
        2024-3-3..2024-4-4___222_222
      ],
      at_school_periods: %w[
        2024-3-1..2024-3-2___111_111
        2024-3-3..2024-4-4___222_222
      ]
    },
    "two IRs share start date. The second ends later than the first one" => {
      induction_records: %w[
        2024-3-3..2024-5-5___111_111
        2024-3-3..2024-6-6___222_222
      ],
      at_school_periods: %w[
        2024-3-1..2024-3-2___111_111
        2024-3-3..2024-6-6___222_222
      ]
    },
    "two IRs. The second starts later and ends earlier than the first one" => {
      induction_records: %w[
        2024-3-3..2024-6-6___111_111
        2024-4-4..2024-5-5___222_222
      ],
      at_school_periods: %w[
        2024-3-3..2024-4-3___111_111
        2024-4-4..2024-5-5___222_222
      ]
    },
    "two IRs. The second starts later and ends the same day the first one does" => {
      induction_records: %w[
        2024-3-3..2024-6-6___111_111
        2024-4-4..2024-6-6___222_222
      ],
      at_school_periods: %w[
        2024-3-3..2024-4-3___111_111
        2024-4-4..2024-6-6___222_222
      ]
    },
    "two IRs. The second starts and ends later than the first one" => {
      induction_records: %w[
        2024-3-3..2024-6-6___111_111
        2024-4-4..2024-7-7___222_222
      ],
      at_school_periods: %w[
        2024-3-3..2024-4-3___111_111
        2024-4-4..2024-7-7___222_222
      ]
    },
    "two IRs. The second starts later than the first one and never ends" => {
      induction_records: %w[
        2024-3-3..2024-6-6___111_111
        2024-4-4..:ignore___222_222
      ],
      at_school_periods: %w[
        2024-3-3..2024-4-3___111_111
        2024-4-4..:ignore___222_222
      ]
    },
    "two IRs starts the same day. The second one never ends" => {
      induction_records: %w[
        2024-3-3..2024-6-6___111_111
        2024-3-3..:ignore___222_222
      ],
      at_school_periods: %w[
        2024-3-1..2024-3-2___111_111
        2024-3-3..:ignore___222_222
      ]
    },
    "two IRs. The first starts later than the second one. The second one never ends" => {
      induction_records: %w[
        2024-4-4..2024-6-6___111_111
        2024-3-3..:ignore___222_222
      ],
      at_school_periods: %w[
        2024-3-1..2024-3-2___111_111
        2024-3-3..:ignore___222_222
      ]
    },
  }.each do |description, data|
    context description do
      let(:induction_records) do
        data[:induction_records].map do |induction_record|
          dates, urn = induction_record.split("___")
          start_date, end_date = dates.split("..").map do |date_or_ignore|
            date_or_ignore == ":ignore" ? :ignore : Time.zone.parse(date_or_ignore)
          end

          {
            start_date:,
            end_date:,
            school: schools.find { |school| school[:urn] == urn.to_i }
          }
        end
      end

      it "creates the right expected number of ECT at school periods" do
        expect(subject.ect_at_school_period_rows.size).to eq(data[:at_school_periods].size)
      end

      it "produces the expected ECT at school periods" do
        aggregate_failures do
          data[:at_school_periods].each_with_index do |at_school_period, i|
            dates, urn = at_school_period.split("___")
            started_on, finished_on = dates.split("..").map do |date_or_ignore|
              date_or_ignore == ":ignore" ? nil : date_or_ignore.to_date
            end

            expect(subject.ect_at_school_period_rows[i].started_on).to eql(started_on)
            expect(subject.ect_at_school_period_rows[i].finished_on).to eql(finished_on)
            expect(subject.ect_at_school_period_rows[i].school.urn).to eql(urn)
          end
        end
      end

      it "creates training periods that span the entire ECT at school period" do
        aggregate_failures do
          subject.ect_at_school_period_rows.each do |school_period|
            expect(school_period.started_on).to eq school_period.training_period_rows.first.started_on
            expect(school_period.finished_on).to eq school_period.training_period_rows.first.finished_on
          end
        end
      end
    end
  end
end
