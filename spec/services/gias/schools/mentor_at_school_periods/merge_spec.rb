RSpec.describe GIAS::Schools::MentorAtSchoolPeriods::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      predecessor_school:,
      successor_school:
    )
  end

  let(:author) { Events::SystemAuthor.new }
  let(:predecessor_gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:predecessor_school) { predecessor_gias_school.school }
  let(:successor_school) { gias_school.school }

  let(:teacher) { FactoryBot.create(:teacher) }

  let(:started_on) { Date.new(2025, 1, 1) }
  let(:finished_on) { Date.new(2025, 12, 31) }

  let(:first_period) { FactoryBot.create(:mentor_at_school_period,  teacher:, school: predecessor_school, started_on:, finished_on: Date.new(2025, 12, 31)) }
  let(:second_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 4, 1), finished_on: Date.new(2025, 9, 30)) }

  let(:successor_period) { second_period }

  let(:periods) { [first_period, second_period] }

  describe "#call" do
    context "when no school partnerships need to be created at the destination school" do
      let!(:first_training_period) { FactoryBot.create(:training_period, :for_mentor,  :with_only_expression_of_interest, mentor_at_school_period: first_period) }
      let!(:second_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_only_expression_of_interest, mentor_at_school_period: second_period) }

      context "when there is one mentor_at_school_period at each school that overlaps" do
        let(:training_periods) { [first_training_period, second_training_period] }

        context "when neither period is ongoing" do
          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "changes the end date" do
            expect { service }.to change(successor_period, :finished_on).to(finished_on)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-1)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end

        context "when the period at the destination school is ongoing" do
          let(:second_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 7, 1), finished_on: nil) }

          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-1)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end

        context "when the period at the original school is ongoing" do
          let(:first_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on:, finished_on: nil) }

          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "changes the end date" do
            expect { service }.to change(successor_period, :finished_on).to(nil)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-1)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end
      end

      context "when there are two mentor periods at the destination school" do
        let(:first_period) { FactoryBot.create(:mentor_at_school_period,  teacher:, school: predecessor_school, started_on:, finished_on: Date.new(2025, 6, 30)) }
        let(:second_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 4, 1), finished_on: Date.new(2025, 7, 31)) }
        let(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 9, 1), finished_on: Date.new(2025, 12, 31)) }
        let!(:third_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_only_expression_of_interest, mentor_at_school_period: third_period) }
        let(:successor_period) { third_period }

        let(:training_periods) { [first_training_period, second_training_period, third_training_period] }
        let(:periods) { [first_period, second_period, third_period] }

        context "when no periods are ongoing" do
          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "changes the end date" do
            expect { service }.not_to change(successor_period, :finished_on)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(second_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end

        context "when the period at the destination school is ongoing" do
          let(:successor_period) { third_period }
          let(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 9, 1), finished_on: nil) }

          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "changes the end date" do
            expect { service }.not_to change(successor_period, :finished_on)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end

        context "when the period at the original school is ongoing" do
          let(:first_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on:, finished_on: nil) }

          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "changes the end date" do
            expect { service }.to change(successor_period, :finished_on).to(nil)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end
      end

      context "when there are two mentor periods at the original school" do
        let(:first_period) { FactoryBot.create(:mentor_at_school_period,  teacher:, school: predecessor_school, started_on:, finished_on: Date.new(2025, 6, 30)) }
        let(:second_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 4, 1), finished_on: Date.new(2025, 11, 30)) }
        let(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on: Date.new(2025, 9, 1), finished_on: Date.new(2025, 12, 31)) }
        let!(:third_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_only_expression_of_interest, mentor_at_school_period: third_period) }

        let(:training_periods) { [first_training_period, second_training_period, third_training_period] }
        let(:periods) { [first_period, second_period, third_period] }

        context "when no periods are ongoing" do
          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "changes the end date" do
            expect { service }.to change(successor_period, :finished_on).to(finished_on)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end

        context "when the period at the destination school is ongoing" do
          let(:second_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 4, 1), finished_on: nil) }

          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end

        context "when the period at the original school is ongoing" do
          let(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on: Date.new(2025, 9, 1), finished_on: nil) }

          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "changes the end date" do
            expect { service }.to change(successor_period, :finished_on).to(nil)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end

        context "when both periods are ongoing" do
          let(:second_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: successor_school, started_on: Date.new(2025, 4, 1), finished_on: nil) }
          let(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on: Date.new(2025, 9, 1), finished_on: nil) }

          it "changes the start date" do
            expect { service }.to change(successor_period, :started_on).to(started_on)
          end

          it "points training periods to the successor period" do
            service

            training_periods.each do |training_period|
              expect(training_period.mentor_at_school_period).to eq(successor_period)
            end
          end

          it "merges the periods" do
            expect { service }.to change(MentorAtSchoolPeriod, :count).by(-2)

            expect(MentorAtSchoolPeriod.exists?(first_period.id)).to be(false)
            expect(MentorAtSchoolPeriod.exists?(successor_period.id)).to be(true)
          end
        end
      end
    end

    context "when a school partnership needs to be reassigned at the destination school" do
      let!(:first_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_school_partnership, mentor_at_school_period: first_period) }
      let!(:second_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_only_expression_of_interest, mentor_at_school_period: second_period) }

      context "when the partnership exists at the destination school" do
        let(:lead_provider_delivery_partnership) { first_training_period.school_partnership.lead_provider_delivery_partnership }
        let!(:partnership_at_destination_school) { FactoryBot.create(:school_partnership, school: successor_school, lead_provider_delivery_partnership:) }

        it "moves the school partnership to the destination school" do
          service

          expect(first_training_period.school_partnership).to eq(partnership_at_destination_school)
        end
      end

      context "when the partnership does not exist at the destination school" do
        let(:school_partnership) { FactoryBot.create(:school_partnership, school: predecessor_school) }
        let!(:first_training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: first_period, school_partnership:) }

        it "creates a new school partnership at the destination school" do
          expect { service }.to change(SchoolPartnership, :count).by(1)

          expect(first_training_period.school_partnership.school).to eq(successor_school)
          expect(first_training_period.school_partnership.lead_provider_delivery_partnership).to eq(school_partnership.lead_provider_delivery_partnership)
        end
      end

      context "when there are two training periods using the same school partnership" do
        let(:school_partnership) { FactoryBot.create(:school_partnership, school: predecessor_school) }
        let(:first_period) { FactoryBot.create(:mentor_at_school_period,  teacher:, school: predecessor_school, started_on:, finished_on: Date.new(2025, 6, 30)) }
        let(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on: Date.new(2025, 9, 1), finished_on: Date.new(2025, 12, 31)) }
        let!(:third_training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: third_period, school_partnership:) }
        let!(:first_training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: first_period, school_partnership:) }

        let(:periods) { [first_period, second_period, third_period] }

        it "creates one new school partnership at the destination school" do
          expect(third_training_period.reload.school_partnership).to eq(first_training_period.reload.school_partnership)

          expect { service }.to change(SchoolPartnership, :count).by(1)

          expect(third_training_period.reload.school_partnership).to eq(first_training_period.reload.school_partnership)
          expect(third_training_period.school_partnership.school).to eq(successor_school)
          expect(first_training_period.school_partnership.school).to eq(successor_school)
        end
      end

      context "when there are two training periods using a different school partnership" do
        let(:first_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on:, finished_on: Date.new(2025, 6, 30)) }
        let(:third_period) { FactoryBot.create(:mentor_at_school_period, teacher:, school: predecessor_school, started_on: Date.new(2025, 9, 1), finished_on: Date.new(2025, 12, 31)) }
        let!(:third_training_period) { FactoryBot.create(:training_period, :with_school_partnership, :for_mentor, mentor_at_school_period: third_period) }
        let!(:first_training_period) { FactoryBot.create(:training_period, :with_school_partnership, :for_mentor, mentor_at_school_period: first_period) }

        let(:periods) { [first_period, second_period, third_period] }

        it "creates one new school partnership at the destination school" do
          expect { service }.to change(SchoolPartnership, :count).by(2)

          expect(third_training_period.school_partnership.school).to eq(successor_school)
          expect(first_training_period.school_partnership.school).to eq(successor_school)
        end
      end
    end

    context "when there is a mentorship period that needs to be reassigned" do
      let(:mentee) { FactoryBot.create(:ect_at_school_period, school: predecessor_school, started_on:, finished_on:) }
      let!(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor: first_period, mentee:, started_on:, finished_on: Date.new(2025, 6, 30)) }

      it "changes the mentorship period to point to the successor period" do
        service

        expect(mentorship_period.mentor).to eq(successor_period)
      end

      context "when the mentee has training periods" do
        let!(:training_period) { FactoryBot.create(:training_period, :with_school_partnership, :for_ect, ect_at_school_period: mentee, started_on:, finished_on: Date.new(2025, 6, 30)) }

        context "when the mentee's training period has a school partnership that needs to be reassigned" do
          it "changes the mentorship period to point to the successor period" do
            service

            expect(mentorship_period.mentor).to eq(successor_period)
          end

          it "recreates the mentee's school partnership at the destination school" do
            expect { service }.to change(SchoolPartnership, :count).by(1)

            expect(training_period.reload.school_partnership.school).to eq(successor_school)
          end

          it "moves the mentee period to the new school" do
            service

            expect(mentee.reload.school).to eq(successor_school)
          end
        end

        context "when the mentee's training period has a school partnership that already exists at the destination school" do
          let!(:training_period) { FactoryBot.create(:training_period, :with_school_partnership, :for_ect, ect_at_school_period: mentee, started_on:, finished_on: Date.new(2025, 6, 30)) }
          let!(:existing_partnership) { FactoryBot.create(:school_partnership, school: successor_school, lead_provider_delivery_partnership: training_period.school_partnership.lead_provider_delivery_partnership) }

          it "changes the mentorship period to point to the successor period" do
            service

            expect(mentorship_period.mentor).to eq(successor_period)
          end

          it "uses the existing partnership" do
            expect { service }.not_to change(SchoolPartnership, :count)

            expect(training_period.reload.school_partnership).to eq(existing_partnership)
          end

          it "moves the mentee period to the new school" do
            service

            expect(mentee.reload.school).to eq(successor_school)
          end
        end

        context "when the mentee's training period only has an expression of interest" do
          let(:expression_of_interest) { FactoryBot.create(:active_lead_provider, :for_year, year: 2025) }
          let!(:training_period) { FactoryBot.create(:training_period, :with_no_school_partnership, :for_ect, expression_of_interest:, ect_at_school_period: mentee, started_on:, finished_on: Date.new(2025, 6, 30)) }

          it "changes the mentorship period to point to the successor period" do
            service

            expect(mentorship_period.mentor).to eq(successor_period)
          end

          it "does not change the expression of interest" do
            expect { service }.not_to change(training_period, :expression_of_interest)

            expect(training_period.school_partnership).to be_nil
          end

          it "moves the mentee period to the new school" do
            service

            expect(mentee.reload.school).to eq(successor_school)
          end
        end
      end

      context "when the mentee has events" do
        let!(:event) { FactoryBot.create(:event, mentor_at_school_period: first_period) }

        it "changes the mentorship period to point to the successor period" do
          service

          expect(mentorship_period.mentor).to eq(successor_period)
        end

        context "when the mentee's event has a school partnership that needs to be reassigned" do
          let(:school_partnership) { FactoryBot.create(:school_partnership, school: predecessor_school) }
          let!(:event) { FactoryBot.create(:event, mentor_at_school_period: first_period, school_partnership:) }

          it "recreates the school partnership at the destination school" do
            expect { service }.to change(SchoolPartnership, :count).by(1)

            expect(event.reload.school_partnership.school).to eq(successor_school)
          end
        end

        context "when the event is linked to the predecessor school" do
          let!(:event) { FactoryBot.create(:event, mentor_at_school_period: first_period, school: predecessor_school) }

          it "moves the event to the new school" do
            service

            expect(event.reload.school).to eq(successor_school)
          end
        end
      end
    end

    context "when there is an event that needs to be reassigned" do
      let!(:event) { FactoryBot.create(:event, mentor_at_school_period: first_period) }

      it "changes the event to point to the successor period" do
        expect { service }.to change { event.reload.mentor_at_school_period }.to(successor_period)
      end

      context "when the event is linked to the predecessor school" do
        let!(:event) { FactoryBot.create(:event, mentor_at_school_period: first_period, school: predecessor_school) }

        it "changes the event to point to the successor period" do
          expect { service }.to change { event.reload.school }.to(successor_school)
        end
      end

      context "when the event is linked to a school partnership" do
        let!(:first_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_school_partnership, mentor_at_school_period: first_period) }
        let!(:event) { FactoryBot.create(:event, mentor_at_school_period: first_period, school_partnership: first_training_period.school_partnership) }

        it "changes the event to point to the successor period" do
          expect { service }.to change { event.reload.mentor_at_school_period }.to(successor_period)
        end
      end
    end

    it "records an event for the periods being merged" do
      expect(Events::Record).to receive(:record_teacher_mentor_at_school_periods_merged!).with(
        author: an_instance_of(Events::SystemAuthor),
        teacher: successor_period.teacher,
        successor_period:,
        mentor_at_school_periods: periods,
        happened_at: predecessor_school.gias_school.closed_on
      )

      service
    end
  end
end
