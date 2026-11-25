describe MentorshipPeriod do
  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:, started_on: 1.year.ago, finished_on: nil) }
    let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on: 5.years.ago, finished_on: nil, teacher: target, school:) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, started_on: 5.years.ago, finished_on: nil, school:) }
    let!(:target) { FactoryBot.create(:teacher) }
    let(:school) { FactoryBot.create(:school) }

    it_behaves_like "a declarative metadata model", on_event: %i[create destroy update]
  end

  describe "associations" do
    it { is_expected.to belong_to(:mentee).class_name("ECTAtSchoolPeriod").with_foreign_key(:ect_at_school_period_id).inverse_of(:mentorship_periods) }
    it { is_expected.to belong_to(:mentor).class_name("MentorAtSchoolPeriod").with_foreign_key(:mentor_at_school_period_id).inverse_of(:mentorship_periods) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:api_reaction_events).class_name("Event") }
  end

  describe ".affected_by" do
    it "returns the event's mentorship period and the mentorship periods of the event's teacher" do
      mentorship_period = FactoryBot.create(:mentorship_period)
      mentored_by_teacher = FactoryBot.create(:mentorship_period)
      mentoring_teacher = FactoryBot.create(:mentorship_period)
      FactoryBot.create(:mentorship_period)

      teacher = mentored_by_teacher.mentor.teacher
      mentoring_teacher.mentee.update!(teacher:)

      expect(MentorshipPeriod.affected_by(Event.new(mentorship_period:, teacher:))).to contain_exactly(mentorship_period, mentored_by_teacher, mentoring_teacher)
    end
  end

  describe "lead providers" do
    let(:school) { FactoryBot.create(:school) }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 2.years.ago.to_date, finished_on: nil) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: 2.years.ago.to_date, finished_on: nil) }
    let(:mentorship_period) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 1.year.ago.to_date, finished_on: nil) }
    let(:ambition_institute) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
    let(:teach_first) { FactoryBot.create(:lead_provider, name: "Teach First") }

    before do
      FactoryBot.create(:training_period, ect_at_school_period:, school_partnership: FactoryBot.create(:school_partnership, :for_year, lead_provider: teach_first, school:), started_on: 2.years.ago.to_date, finished_on: 1.year.ago.to_date)
      FactoryBot.create(:training_period, ect_at_school_period:, school_partnership: FactoryBot.create(:school_partnership, :for_year, lead_provider: ambition_institute, school:), started_on: 1.year.ago.to_date.tomorrow, finished_on: nil)
    end

    describe "#lead_providers" do
      it "returns the lead providers training the ECT since the mentorship started" do
        expect(mentorship_period.lead_providers).to contain_exactly(ambition_institute)
      end

      it "leaves out lead providers training the ECT in a contract period that is not open" do
        ContractPeriod.find_by!(year: 2024).update!(enabled: false)

        expect(mentorship_period.lead_providers).to be_empty
      end
    end

    describe "#lead_providers_no_longer_involved" do
      it "returns lead providers with API events for the mentorship that are no longer involved and have not been told" do
        best_practice_network = FactoryBot.create(:lead_provider, name: "Best Practice Network")
        FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_created, mentorship_period:, lead_provider: teach_first)
        FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_created, mentorship_period:, lead_provider: ambition_institute)
        FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_created, mentorship_period:, lead_provider: best_practice_network)
        FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_deleted, mentorship_period:, lead_provider: best_practice_network)

        expect(mentorship_period.lead_providers_no_longer_involved).to contain_exactly(teach_first)
      end
    end
  end

  describe "#latest_emitted_payload" do
    let(:mentorship_period) { FactoryBot.create(:mentorship_period) }
    let(:ambition_institute) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
    let(:teach_first) { FactoryBot.create(:lead_provider, name: "Teach First") }

    before do
      FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_created, mentorship_period:, lead_provider: ambition_institute, metadata: { payload: { "mentor_email" => "first@example.com" } })
      FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_updated, mentorship_period:, lead_provider: ambition_institute, metadata: { payload: { "mentor_email" => "second@example.com" } })
      FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_updated, mentorship_period:, lead_provider: teach_first, metadata: { payload: { "mentor_email" => "other@example.com" } })
    end

    it "returns the payload on the lead provider's latest API event" do
      expect(mentorship_period.latest_emitted_payload(lead_provider: ambition_institute)).to eq("mentor_email" => "second@example.com")
      expect(mentorship_period.latest_emitted_payload(lead_provider: FactoryBot.create(:lead_provider))).to be_nil
    end

    it "returns nothing once the latest API event is a deletion" do
      FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_deleted, mentorship_period:, lead_provider: ambition_institute, metadata: { payload: nil })

      expect(mentorship_period.latest_emitted_payload(lead_provider: ambition_institute)).to be_nil
    end
  end

  describe "#latest_relevant_timestamp" do
    context "with created, updated and deleted API events" do
      let(:mentorship_period) { FactoryBot.create(:mentorship_period) }
      let(:ambition_institute) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
      let(:teach_first) { FactoryBot.create(:lead_provider, name: "Teach First") }
      let!(:updated) { FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_updated, mentorship_period:, lead_provider: ambition_institute, happened_at: 2.days.ago) }

      before do
        FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_created, mentorship_period:, lead_provider: ambition_institute, happened_at: 3.days.ago)
        FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_deleted, mentorship_period:, lead_provider: ambition_institute, happened_at: 1.day.ago)
        FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_updated, mentorship_period:, lead_provider: teach_first, happened_at: 1.hour.ago)
      end

      it "returns when the lead provider's view of the mentorship last changed" do
        expect(mentorship_period.latest_relevant_timestamp(lead_provider: ambition_institute)).to eq(updated.happened_at)
        expect(mentorship_period.latest_relevant_timestamp(lead_provider: FactoryBot.create(:lead_provider))).to be_nil
      end
    end

    context "when another mentorship has a later API event" do
      let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
      let(:mentorship_period) { FactoryBot.create(:mentorship_period) }
      let!(:updated) { FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_updated, mentorship_period:, lead_provider:, happened_at: 1.day.ago) }

      before { FactoryBot.create(:event, author_type: "system", event_type: :api_mentorship_updated, lead_provider:, happened_at: 1.hour.ago) }

      it "returns when the lead provider's view of this mentorship last changed" do
        expect(mentorship_period.latest_relevant_timestamp(lead_provider:)).to eq(updated.happened_at)
      end
    end

    describe "compared with updated_at" do
      let(:author) { Events::SystemAuthor.new }
      let(:school) { FactoryBot.create(:school) }
      let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
      let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, lead_provider:, school:) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 1.year.ago.to_date, finished_on: nil) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: 1.year.ago.to_date, finished_on: nil) }
      let(:mentee) { ect_at_school_period.teacher }
      let(:mentor) { mentor_at_school_period.teacher }
      let(:mentorship_period) do
        FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 6.months.ago.to_date, finished_on: nil)
      end

      before do
        FactoryBot.create(:training_period, ect_at_school_period:, school_partnership:, started_on: 1.year.ago.to_date, finished_on: nil)

        perform_enqueued_jobs do
          Events::Record.record_teacher_starts_being_mentored_event!(author:, mentor:, mentee:, ect_at_school_period:, mentorship_period:, school:)
        end
      end

      def make_change_visible_to_lead_provider!
        MentorshipPeriods::Finish.new(mentorship_period:, finished_on: Date.current, author:).finish!
      end

      def make_change_invisible_to_lead_provider!
        mentorship_period.update!(ecf_end_induction_record_id: SecureRandom.uuid)
        Events::Record.record_admin_data_fix_event!(
          author:,
          body: "Linked the ECF end induction record",
          zendesk_ticket_id: nil,
          modifications: mentorship_period.saved_changes,
          metadata: { gid: mentorship_period.to_global_id.to_s, action: "update" },
          record: mentorship_period
        )
      end

      it "moves, like updated_at, when the lead provider can see the change" do
        travel 1.day

        expect { make_change_visible_to_lead_provider! }.to emit_events(
          [:api_mentorship_updated, { lead_provider:, mentorship_period: }]
        )
        expect(mentorship_period.updated_at).to eq(Time.current)
        expect(mentorship_period.latest_relevant_timestamp(lead_provider:)).to eq(Time.current)
      end

      it "does not move, unlike updated_at, when the lead provider cannot see the change" do
        timestamp_before = mentorship_period.latest_relevant_timestamp(lead_provider:)
        travel 1.day

        expect { make_change_invisible_to_lead_provider! }.to emit_no_events
        expect(mentorship_period.updated_at).to eq(Time.current)
        expect(mentorship_period.latest_relevant_timestamp(lead_provider:)).to eq(timestamp_before)
      end
    end
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

    let(:school) { FactoryBot.create(:school) }
    let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, started_on: 2.years.ago, school:) }
    let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, started_on: 2.years.ago, school:) }
    let(:started_on) { 2.months.ago }
    let(:finished_on) { nil }

    it { is_expected.to validate_presence_of(:started_on) }
    it { is_expected.to validate_presence_of(:ect_at_school_period_id) }
    it { is_expected.to validate_presence_of(:mentor_at_school_period_id) }

    describe "overlapping periods" do
      let(:started_on_message) { "Start date cannot overlap another Mentee period" }
      let(:finished_on_message) { "End date cannot overlap another Mentee period" }
      let(:overlap_message) { "Period cannot overlap another Mentee period" }

      describe "#mentee_distinct_period" do
        PeriodHelpers::PeriodExamples.period_examples.each do |test|
          context test.description do
            let(:school) { FactoryBot.create(:school) }
            let(:mentor) do
              FactoryBot.create(:mentor_at_school_period,
                                started_on: 5.years.ago,
                                finished_on: nil,
                                school:)
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
                                finished_on: nil,
                                school:)
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
                case test.description
                when "when the existing period contains the new one"
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when "when the new period starts before the existing one has finished"
                  expect(messages[:started_on]).to include(started_on_message)
                  expect(messages).not_to have_key(:finished_on)
                when "when the new period finishes after the existing one has started"
                  expect(messages).not_to have_key(:started_on)
                  expect(messages[:finished_on]).to include(finished_on_message)
                when "when the new period envelops the existing one"
                  expect(messages).not_to have_key(:started_on)
                  expect(messages).not_to have_key(:finished_on)
                  expect(messages[:base]).to include(overlap_message)
                else
                  fail "test case didn't match an expectation"
                end
              end
            end
          end
        end
      end
    end

    describe "concurrent ongoing periods" do
      subject(:save_concurrent_ongoing_period!) do
        concurrent_ongoing_period.save!
      end

      before { freeze_time }

      context "for mentees" do
        let(:mentee_teacher) { FactoryBot.create(:teacher) }

        # Mentor mentoring mentee
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            teacher: mentee_teacher,
            started_on: 1.year.ago,
            finished_on: 2.weeks.from_now
          )
        end
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school: ect_at_school_period.school,
            started_on: 1.year.ago
          )
        end
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: 1.year.ago,
            finished_on: 2.weeks.ago
          )
        end

        # Mentee transferring to a new school and being mentored by a different teacher
        let(:next_ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :unfinished,
            teacher: mentee_teacher,
            started_on: ect_at_school_period.finished_on.advance(days: 1)
          )
        end
        let(:next_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school: next_ect_at_school_period.school,
            started_on: 1.year.ago
          )
        end
        let!(:ongoing_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            mentee: next_ect_at_school_period,
            mentor: next_mentor_at_school_period,
            started_on: next_ect_at_school_period.started_on
          )
        end

        # Mentee being mentored by the original mentor at the old school
        let(:concurrent_ongoing_period) do
          FactoryBot.build(
            :mentorship_period,
            :unfinished,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: mentorship_period.finished_on
          )
        end

        it do
          expect { save_concurrent_ongoing_period! }
            .to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "for mentors" do
        let(:mentor_teacher) { FactoryBot.create(:teacher) }

        # Mentor mentoring mentee at one school
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :unfinished,
            started_on: 1.year.ago
          )
        end
        let(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            school: ect_at_school_period.school,
            teacher: mentor_teacher,
            started_on: 1.year.ago,
            finished_on: 2.weeks.from_now
          )
        end
        let!(:mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentor: mentor_at_school_period,
            mentee: ect_at_school_period,
            started_on: 1.year.ago,
            finished_on: 2.weeks.from_now
          )
        end

        # Mentor tranferring to another school and mentoring another mentee
        let(:next_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :unfinished,
            school: next_ect_at_school_period.school,
            teacher: mentor_teacher,
            started_on: mentor_at_school_period.finished_on.advance(days: 1)
          )
        end
        let(:next_ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :unfinished,
            started_on: mentor_at_school_period.finished_on.advance(days: 1)
          )
        end
        let!(:ongoing_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            :unfinished,
            mentor: next_mentor_at_school_period,
            mentee: next_ect_at_school_period,
            started_on: next_mentor_at_school_period.started_on
          )
        end

        # Mentor mentoring another mentee concurrently at that same school
        let(:other_next_ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :unfinished,
            school: next_ect_at_school_period.school,
            started_on: next_mentor_at_school_period.started_on.advance(weeks: 1)
          )
        end
        let(:concurrent_ongoing_period) do
          FactoryBot.build(
            :mentorship_period,
            :unfinished,
            mentor: next_mentor_at_school_period,
            mentee: other_next_ect_at_school_period,
            started_on: other_next_ect_at_school_period.started_on
          )
        end

        it { expect { save_concurrent_ongoing_period! }.not_to raise_error }
      end
    end

    describe "period containment" do
      describe "#enveloped_by_ect_at_school_period" do
        context "when the ECT at school period contains the mentorship period" do
          subject! { FactoryBot.create(:mentorship_period, started_on: 3.months.ago, finished_on: 2.months.ago, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

          let(:school) { FactoryBot.create(:school) }
          let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 4.months.ago, finished_on: 1.month.ago) }
          let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: 4.months.ago, finished_on: 1.month.ago) }

          it "is valid" do
            expect(subject).to be_valid
          end
        end

        context "when the mentorship period extends beyond the teacher and mentor at school periods" do
          subject { FactoryBot.build(:mentorship_period, started_on: 5.months.ago, finished_on: 1.month.ago, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

          let(:school) { FactoryBot.create(:school) }
          let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 4.months.ago, finished_on: 1.month.ago) }
          let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: 4.months.ago, finished_on: 1.month.ago) }

          it "has an appropriate error message about the ECT at school period" do
            subject.valid?

            expect(subject).to have_error(:base, "Date range is not contained by the ECT at school period")
          end

          it "has an appropriate error message about the mentor at school period" do
            subject.valid?

            expect(subject).to have_error(:base, "Date range is not contained by the mentor at school period")
          end
        end
      end
    end

    describe "#not_self_mentoring" do
      context "when mentor and mentee are the same teacher" do
        subject { FactoryBot.build(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

        let!(:teacher) { ect_at_school_period.teacher }
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, teacher:) }

        it "add a base error" do
          subject.valid?

          expect(subject).to have_error(:base, "A mentee cannot mentor themself")
        end
      end

      context "when mentor and mentee are different teachers" do
        subject { FactoryBot.build(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period) }

        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished) }

        it "do not add an error" do
          subject.valid?

          expect(subject).to have_no_error(:base, "A mentee cannot mentor themself")
        end
      end

      context "when mentor or mentee are not set yet" do
        subject { FactoryBot.build(:mentorship_period, mentor: mentor_at_school_period) }

        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished) }

        it "do not add an error" do
          subject.valid?

          expect(subject).to have_no_error(:base, "A mentee cannot mentor themself")
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
          FactoryBot.create(:ect_at_school_period, :unfinished, school: school_1)
        end

        let!(:mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :unfinished, school: school_1)
        end

        it "is valid" do
          expect(subject).to be_valid
          expect(subject).to have_no_error(:base, "Mentor and mentee periods must belong to the same school")
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
          FactoryBot.create(:ect_at_school_period, :unfinished, school: school_1)
        end

        let!(:mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :unfinished, school: school_2)
        end

        it "adds a base error" do
          subject.valid?

          expect(subject).to have_error(:base, "Mentor and mentee periods must belong to the same school")
        end
      end

      context "when mentor or mentee is missing" do
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, school: school_1) }
        let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, school: school_2) }

        it "does not add an error when mentee is missing" do
          period = FactoryBot.build(
            :mentorship_period,
            mentee: nil,
            mentor: mentor_at_school_period,
            started_on: 1.month.ago,
            finished_on: nil
          )

          period.valid?

          expect(period).to have_no_error(:base, "Mentor and mentee periods must belong to the same school")
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

          expect(period).to have_no_error(:base, "Mentor and mentee periods must belong to the same school")
        end
      end
    end
  end

  describe "check constraints" do
    subject { FactoryBot.build(:mentorship_period, mentee:, mentor:, started_on: Date.current, finished_on: Date.yesterday) }

    let(:mentee) { FactoryBot.create(:ect_at_school_period) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period) }

    it "prevents periods with a duration less than 1 day from being written to the database" do
      expect { subject.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /PG::DataException/)
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
    let!(:mentee) { FactoryBot.create(:ect_at_school_period, :unfinished, started_on: "2021-01-01", school:) }
    let!(:mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, started_on: "2021-01-01", school:) }
    let!(:period_1) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: "2022-01-01", finished_on: "2022-06-01") }
    let!(:period_2) { FactoryBot.create(:mentorship_period, mentee:, mentor:, started_on: "2022-06-02", finished_on: "2023-01-01") }

    let!(:unrelated_mentee) { FactoryBot.create(:ect_at_school_period, :unfinished, started_on: "2021-01-01", school:) }
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
