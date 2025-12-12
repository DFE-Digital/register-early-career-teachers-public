describe MentorshipPeriod do
  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:mentorship_period, :ongoing, mentee:, mentor:, started_on: 1.year.ago, finished_on: nil) }
    let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on: 5.years.ago, finished_on: nil, teacher: target, school:) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, started_on: 5.years.ago, finished_on: nil, school:) }
    let!(:target) { FactoryBot.create(:teacher) }
    let(:school) { FactoryBot.create(:school) }

    it_behaves_like "a declarative metadata model", on_event: %i[create destroy]
  end

  describe "associations" do
    it { is_expected.to belong_to(:mentee).class_name("ECTAtSchoolPeriod").with_foreign_key(:ect_at_school_period_id).inverse_of(:mentorship_periods) }
    it { is_expected.to belong_to(:mentor).class_name("MentorAtSchoolPeriod").with_foreign_key(:mentor_at_school_period_id).inverse_of(:mentorship_periods) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject do
      FactoryBot.build(
        :mentorship_period,
        started_on:,
        finished_on:,
        mentee: ect_at_school_period,
        mentor: mentor_at_school_period
      )
    end

    let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 2.years.ago) }
    let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: 2.years.ago) }
    let(:started_on) { 2.months.ago }
    let(:finished_on) { nil }

    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:ect_at_school_period_id) }
    it { is_expected.to validate_presence_of(:mentor_at_school_period_id) }

    describe "overlapping periods" do
      let(:started_on_message) { "Start date cannot overlap another Mentee period" }
      let(:finished_on_message) { "End date cannot overlap another Mentee period" }

      describe "#mentee_distinct_period" do
        PeriodHelpers::PeriodExamples.period_examples.each_with_index do |test, index|
          context test.description do
            let(:mentor) do
              FactoryBot.create(:mentor_at_school_period,
                                started_on: 5.years.ago,
                                finished_on: nil)
            end
            let(:period) do
              FactoryBot.build(:mentorship_period, mentee:, mentor:,
                                                   started_on: test.new_period_range.first,
                                                   finished_on: test.new_period_range.last)
            end
            let(:messages) { period.errors.messages }

            let(:mentee) do
              FactoryBot.create(:ect_at_school_period,
                                started_on: 5.years.ago,
                                finished_on: nil)
            end

            before do
              FactoryBot.create(:mentorship_period, mentee:, mentor:,
                                                    started_on: test.existing_period_range.first,
                                                    finished_on: test.existing_period_range.last)
              period.valid?
            end

            it "is #{test.expected_valid ? 'valid' : 'invalid'}" do
              if test.expected_valid
                expect(messages).not_to have_key(:started_on)
                expect(messages).not_to have_key(:finished_on)
              else
                case index
                when 0
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 1
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when 2
                  expect(messages).not_to have_key(:started_on)
                  expect(messages[:finished_on]).to include(finished_on_message)
                end
              end
            end
          end
        end
      end
    end

    describe "period containment" do
      describe "#enveloped_by_ect_at_school_period" do
        context "when the ECT at school period contains the mentorship period" do
          subject! { FactoryBot.create(:mentorship_period, started_on: 3.months.ago, finished_on: 2.months.ago, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

          let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 4.months.ago, finished_on: 1.month.ago) }
          let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: 4.months.ago, finished_on: 1.month.ago) }

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        context "when the mentorship period extends beyond the teacher and mentor at school periods" do
          subject { FactoryBot.build(:mentorship_period, started_on: 5.months.ago, finished_on: 1.month.ago, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

          let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, started_on: 4.months.ago, finished_on: 1.month.ago) }
          let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, started_on: 4.months.ago, finished_on: 1.month.ago) }

          it "has an appropriate error message about the ECT at school period" do
            subject.valid?

            expect(subject.errors.messages[:base]).to include("Date range is not contained by the ECT at school period")
          end

          it "has an appropriate error message about the mentor at school period" do
            subject.valid?

            expect(subject.errors.messages[:base]).to include("Date range is not contained by the mentor at school period")
          end
        end
      end
    end

    describe "#not_self_mentoring" do
      context "when mentor and mentee are the same teacher" do
        subject { FactoryBot.build(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

        let!(:teacher) { ect_at_school_period.teacher }
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:) }

        it "add a base error" do
          subject.valid?

          expect(subject.errors.messages[:base]).to include("A mentee cannot mentor themself")
        end
      end

      context "when mentor and mentee are different teachers" do
        subject { FactoryBot.build(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing) }

        it "do not add an error" do
          subject.valid?

          expect(subject.errors.messages[:base]).not_to include("A mentee cannot mentor themself")
        end
      end

      context "when mentor or mentee are not set yet" do
        subject { FactoryBot.build(:mentorship_period, mentor: mentor_at_school_period) }

        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing) }

        it "do not add an error" do
          subject.valid?

          expect(subject.errors.messages[:base]).not_to include("A mentee cannot mentor themself")
        end
      end
    end

    describe "#mentor_and_mentee_periods_are_at_same_school" do
      let(:school_1) { FactoryBot.create(:school) }
      let(:school_2) { FactoryBot.create(:school) }

      context "when mentor and mentee periods are at the same school" do
        subject do
          FactoryBot.build(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: 1.month.ago,
            finished_on: nil
          )
        end

        let!(:ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period, :ongoing, school: school_1)
        end

        let!(:mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :ongoing, school: school_1)
        end

        it "is valid" do
          expect(subject).to be_valid
          expect(subject.errors[:base]).not_to include("Mentor and mentee periods must belong to the same school")
        end
      end

      context "when mentor and mentee periods are at different schools" do
        subject do
          FactoryBot.build(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: 1.month.ago,
            finished_on: nil
          )
        end

        let!(:ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period, :ongoing, school: school_1)
        end

        let!(:mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :ongoing, school: school_2)
        end

        it "adds a base error" do
          subject.valid?

          expect(subject.errors[:base]).to include("Mentor and mentee periods must belong to the same school")
        end
      end

      context "when mentor or mentee is missing" do
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school: school_1) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school: school_2) }

        it "does not add an error when mentee is missing" do
          period = FactoryBot.build(
            :mentorship_period,
            mentee: nil,
            mentor: mentor_at_school_period,
            started_on: 1.month.ago,
            finished_on: nil
          )

          period.valid?

          expect(period.errors[:base]).not_to include("Mentor and mentee periods must belong to the same school")
        end

        it "does not add an error when mentor is missing" do
          period = FactoryBot.build(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: nil,
            started_on: 1.month.ago,
            finished_on: nil
          )

          period.valid?

          expect(period.errors[:base]).not_to include("Mentor and mentee periods must belong to the same school")
        end
      end
    end
  end

  describe "check constraints" do
    subject { FactoryBot.build(:mentorship_period, mentee:, mentor:, started_on: Date.current, finished_on: Date.current) }

    let(:mentee) { FactoryBot.create(:ect_at_school_period) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period) }

    it "prevents 0 day periods from being written to the database" do
      expect { subject.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /PG::CheckViolation/)
    end
  end

  describe "scopes" do
    describe ".for_mentee" do
      it "returns only periods for the specified mentee" do
        expect(MentorshipPeriod.for_mentee(123).to_sql).to end_with(%(WHERE "mentorship_periods"."ect_at_school_period_id" = 123))
      end
    end

    describe ".for_mentor" do
      it "returns only periods for the specified mentor" do
        expect(MentorshipPeriod.for_mentor(456).to_sql).to end_with(%(WHERE "mentorship_periods"."mentor_at_school_period_id" = 456))
      end
    end
  end

  describe "#siblings" do
    subject { period_1.siblings }

    let(:school) { FactoryBot.create(:school) }
    let!(:mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: "2021-01-01", school:) }
    let!(:mentor) { FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: "2021-01-01", school:) }
    let!(:period_1) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: "2022-01-01", finished_on: "2022-06-01") }
    let!(:period_2) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: "2022-06-01", finished_on: "2023-01-01") }

    let!(:unrelated_mentee) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: "2021-01-01", school:) }
    let!(:unrelated_period) { FactoryBot.create(:mentorship_period, mentor:, mentee: unrelated_mentee, started_on: "2022-06-01", finished_on: "2023-01-01") }

    it "only returns records that belong to the same mentee" do
      expect(subject).to include(period_2)
    end

    it "doesn't include itself" do
      expect(subject).not_to include(period_1)
    end

    it "doesn't include periods that belong to other mentees" do
      expect(subject).not_to include(unrelated_period)
    end
  end
end
