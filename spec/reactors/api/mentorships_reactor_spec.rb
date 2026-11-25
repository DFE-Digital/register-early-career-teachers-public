RSpec.describe API::MentorshipsReactor do
  let(:author) { Events::SystemAuthor.new }
  let(:school) { FactoryBot.create(:school) }
  let(:ambition_institute) { FactoryBot.create(:lead_provider, name: "Ambition Institute") }
  let(:teach_first) { FactoryBot.create(:lead_provider, name: "Teach First") }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 1.year.ago.to_date, finished_on: nil) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, started_on: 1.year.ago.to_date, finished_on: nil) }
  let(:mentee) { ect_at_school_period.teacher }
  let(:mentor) { mentor_at_school_period.teacher }
  let(:mentorship_period) do
    FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 6.months.ago.to_date, finished_on: nil)
  end
  let!(:training_period) { training_period_with(lead_provider: ambition_institute, started_on: 1.year.ago.to_date) }

  def training_period_with(lead_provider:, started_on:)
    school_partnership = FactoryBot.create(:school_partnership, :for_year, lead_provider:, school:)

    FactoryBot.create(:training_period, ect_at_school_period:, school_partnership:, started_on:, finished_on: nil)
  end

  describe "#react_to!" do
    it "tells each lead provider training the ECT about a new mentorship" do
      expect {
        Events::Record.record_teacher_starts_being_mentored_event!(author:, mentor:, mentee:, ect_at_school_period:, mentorship_period:, school:)
      }.to emit_events(
        [:api_mentorship_created, { lead_provider: ambition_institute, mentorship_period: }]
      )
    end

    it "ignores events about a whole school" do
      school_user = Sessions::Users::SchoolUser.new(
        email: "velma.dinkley@example.com",
        name: "Velma Dinkley",
        school_urn: school.urn,
        dfe_sign_in_organisation_id: SecureRandom.uuid,
        dfe_sign_in_user_id: SecureRandom.uuid,
        dfe_sign_in_roles: %w[SchoolUser]
      )

      expect {
        Events::Record.record_school_user_signs_in_event!(author: school_user, school:)
      }.not_to have_enqueued_job(Events::ReactToEventJob)
    end

    context "when the lead provider already knows about the mentorship" do
      before do
        perform_enqueued_jobs do
          Events::Record.record_teacher_starts_being_mentored_event!(author:, mentor:, mentee:, ect_at_school_period:, mentorship_period:, school:)
        end
      end

      it "updates the lead provider when the mentorship finishes" do
        expect {
          MentorshipPeriods::Finish.new(mentorship_period:, finished_on: Date.current, author:).finish!
        }.to emit_events(
          [:api_mentorship_updated, { lead_provider: ambition_institute, mentorship_period: }]
        )
      end

      it "updates the lead provider once when the mentor's email changes" do
        change_email = -> do
          old_email = mentor_at_school_period.email
          mentor_at_school_period.update!(email: "mentor@example.com")
          Events::Record.record_teacher_email_updated_event!(old_email:, new_email: "mentor@example.com", author:, school:, teacher: mentor, mentor_at_school_period:, happened_at: Time.current)
        end

        expect(&change_email).to emit_events(
          [:api_mentorship_updated, { lead_provider: ambition_institute, mentorship_period: }]
        )
        expect(&change_email).to emit_no_events
      end

      it "updates the lead provider when the mentor's name changes" do
        old_name = mentor.full_name

        expect {
          mentor.update!(corrected_name: "Chang Cummings")
          Events::Record.teacher_name_updated_by_user_event!(old_name:, new_name: "Chang Cummings", author:, teacher: mentor)
        }.to emit_events(
          [:api_mentorship_updated, { lead_provider: ambition_institute, mentorship_period: }]
        )
      end

      it "updates the lead provider when the ECT's TRN is replaced" do
        old_trn = mentee.trn

        expect {
          mentee.update!(trn: "9876543")
          Events::Record.record_teacher_trn_replaced_event!(teacher: mentee, author:, old_trn:, new_trn: "9876543")
        }.to emit_events(
          [:api_mentorship_updated, { lead_provider: ambition_institute, mentorship_period: }]
        )
      end

      context "when the ECT's lead provider is changed" do
        include_context "safe_schedules"

        let(:contract_period) { FactoryBot.create(:contract_period, :current, :with_schedules) }
        let(:ambition_institute_framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider: ambition_institute, contract_period:) }
        let(:teach_first_framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider: teach_first, contract_period:) }
        let(:ambition_institute_school_partnership) do
          FactoryBot.create(:school_partnership, :with_framework_agreement, framework_agreement: ambition_institute_framework_agreement, school:)
        end
        let!(:teach_first_school_partnership) do
          FactoryBot.create(:school_partnership, :with_framework_agreement, framework_agreement: teach_first_framework_agreement, school:)
        end
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :provider_led,
            ect_at_school_period:,
            school_partnership: ambition_institute_school_partnership,
            started_on: ect_at_school_period.started_on,
            finished_on: nil
          )
        end
        let(:change_lead_provider) do
          ECTAtSchoolPeriods::ChangeLeadProvider.call(ect_at_school_period, new_lead_provider: teach_first, old_lead_provider: ambition_institute, author:)
        end

        context "before training has started" do
          let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: Date.current, finished_on: nil) }
          let(:mentorship_period) do
            FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: Date.current, finished_on: nil)
          end

          it "moves the mentorship to the new lead provider without sending the old one any details" do
            expect { change_lead_provider }.to emit_events(
              [:api_mentorship_deleted, { lead_provider: ambition_institute, mentorship_period: }],
              [:api_mentorship_created, { lead_provider: teach_first, mentorship_period: }]
            )

            expect(mentorship_period.api_reaction_events.find_by(event_type: "api_mentorship_deleted").metadata["payload"]).to be_nil
          end

          it "gives the mentorship back to the old lead provider when the change is reversed" do
            perform_enqueued_jobs { change_lead_provider }

            expect {
              ECTAtSchoolPeriods::ChangeLeadProvider.call(ect_at_school_period, new_lead_provider: ambition_institute, old_lead_provider: teach_first, author:)
            }.to emit_events(
              [:api_mentorship_deleted, { lead_provider: teach_first, mentorship_period: }],
              [:api_mentorship_created, { lead_provider: ambition_institute, mentorship_period: }]
            )
          end

          it "does not delete the mentorship again for the old lead provider" do
            perform_enqueued_jobs { change_lead_provider }

            expect {
              Events::Record.record_teacher_working_pattern_updated_event!(
                old_working_pattern: "full_time", new_working_pattern: "part_time", author:,
                ect_at_school_period:, school:, teacher: mentee, happened_at: Time.current
              )
            }.to emit_no_events
          end
        end

        context "after training has started" do
          let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, started_on: 2.weeks.ago.to_date, finished_on: nil) }
          let(:mentorship_period) do
            FactoryBot.create(:mentorship_period, mentee: ect_at_school_period, mentor: mentor_at_school_period, started_on: 1.week.ago.to_date, finished_on: nil)
          end

          it "tells the new lead provider while the old one keeps the mentorship" do
            expect { change_lead_provider }.to emit_events(
              [:api_mentorship_created, { lead_provider: teach_first, mentorship_period: }]
            )
          end
        end
      end

      it "emits nothing when the ECT's working pattern changes" do
        expect {
          Events::Record.record_teacher_working_pattern_updated_event!(
            old_working_pattern: "full_time", new_working_pattern: "part_time", author:,
            ect_at_school_period:, school:, teacher: mentee, happened_at: Time.current
          )
        }.to emit_no_events
      end
    end
  end

  describe "reacting to the same event again" do
    it "records nothing the second time" do
      event = perform_enqueued_jobs do
        Events::Record.record_teacher_starts_being_mentored_event!(author:, mentor:, mentee:, ect_at_school_period:, mentorship_period:, school:)
      end

      expect { described_class.react_to!(event) }.not_to change(Event.api_reaction_events, :count)
    end
  end
end
