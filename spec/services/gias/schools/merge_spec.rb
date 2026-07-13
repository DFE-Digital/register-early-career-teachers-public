RSpec.describe GIAS::Schools::Merge do
  describe "#merge!" do
    subject(:merge_school) { described_class.new(gias_school).merge! }

    let(:predecessor_school) { gias_school.school }
    let(:successor_school) { successor_gias_school.school }
    let(:teacher) { FactoryBot.create(:teacher) }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :closed) }
    let(:successor_gias_school) { FactoryBot.create(:gias_school, :with_school, :open) }

    let!(:school_link) { FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: gias_school, to_gias_school: successor_gias_school) }

    let(:can_be_merged) { true }

    before do
      allow(gias_school).to receive(:can_be_merged?).and_return(can_be_merged)
    end

    context "when the school cannot be merged" do
      let(:can_be_merged) { false }

      let(:school_partnership) { FactoryBot.create(:school_partnership, school: predecessor_school) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school: predecessor_school) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :with_school_partnership, ect_at_school_period:, school_partnership:) }

      let!(:mentor_period_at_predecessor) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: predecessor_school,
          started_on: Date.new(2025, 1, 1),
          finished_on: Date.new(2025, 3, 31)
        )
      end

      let!(:mentor_period_at_successor) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school: successor_school,
          started_on: Date.new(2025, 3, 1),
          finished_on: Date.new(2025, 6, 30)
        )
      end

      it { expect(merge_school).to be_falsey }

      it "does not merge any periods" do
        allow(GIAS::Schools::MentorAtSchoolPeriods::Merge).to receive(:call)

        expect { merge_school }.not_to change(MentorAtSchoolPeriod, :count)

        expect(GIAS::Schools::MentorAtSchoolPeriods::Merge).not_to have_received(:call)
      end

      it "does not move any periods" do
        allow(GIAS::Schools::MentorAtSchoolPeriods::Transfer).to receive(:call)
        allow(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to receive(:call)

        merge_school

        expect(GIAS::Schools::MentorAtSchoolPeriods::Transfer).not_to have_received(:call)
        expect(GIAS::Schools::ECTAtSchoolPeriods::Transfer).not_to have_received(:call)

        expect(mentor_period_at_predecessor.reload.school).to eq(predecessor_school)
        expect(mentor_period_at_successor.reload.school).to eq(successor_school)
        expect(ect_at_school_period.reload.school).to eq(predecessor_school)
      end

      it "does not move any school partnerships" do
        expect { merge_school }.not_to change(SchoolPartnership, :count)

        expect(training_period.reload.school_partnership.school).to eq(predecessor_school)
      end

      it "does not record a school merged event" do
        expect(Events::Record).not_to receive(:record_school_merged_event!)

        merge_school
      end
    end

    context "when the school can be merged" do
      context "when there are teachers with periods at the predecessor school" do
        context "when there is a teacher mentoring at the predecessor school only" do
          let(:mentor_without_overlapping_periods) do
            FactoryBot.create(:mentor_at_school_period,
                              school: predecessor_school,
                              started_on: Date.new(2025, 7, 1),
                              finished_on: Date.new(2025, 12, 31))
          end

          let(:mentees) do
            FactoryBot.create_list(:ect_at_school_period, 2,
                                   school: predecessor_school,
                                   started_on: Date.new(2025, 7, 2),
                                   finished_on: Date.new(2025, 12, 30))
          end

          before do
            mentees.each do |mentee|
              FactoryBot.create(:mentorship_period, mentor: mentor_without_overlapping_periods, mentee:)
            end
          end

          it { expect(merge_school).to be_truthy }

          it "moves mentor periods without overlaps to the successor school" do
            allow(GIAS::Schools::MentorAtSchoolPeriods::Transfer).to receive(:call).and_call_original
            allow(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to receive(:call).and_call_original

            merge_school

            expect(GIAS::Schools::MentorAtSchoolPeriods::Transfer).to have_received(:call).once
            expect(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to have_received(:call).twice

            expect(mentor_without_overlapping_periods.reload.school).to eq(successor_school)
            mentees.each do |mentee|
              expect(mentee.reload.school).to eq(successor_school)
            end
          end

          it "records a school merged event" do
            expect(Events::Record).to receive(:record_school_merged_event!)
              .once
              .with(school: successor_school,
                    predecessor_gias_school: gias_school,
                    successor_gias_school:,
                    happened_at: gias_school.closed_on,
                    author: an_instance_of(Events::SystemAuthor))

            merge_school
          end
        end

        context "when there is a teacher who mentors at both schools and has overlapping periods" do
          let!(:mentor_period_at_predecessor) do
            FactoryBot.create(
              :mentor_at_school_period,
              teacher:,
              school: predecessor_school,
              started_on: Date.new(2025, 1, 1),
              finished_on: Date.new(2025, 3, 31)
            )
          end

          let!(:mentor_period_at_successor) do
            FactoryBot.create(
              :mentor_at_school_period,
              teacher:,
              school: successor_school,
              started_on: Date.new(2025, 3, 1),
              finished_on: Date.new(2025, 6, 30)
            )
          end

          it { expect(merge_school).to be_truthy }

          it "merges overlapping mentor periods and moves remaining periods to the successor school" do
            expect { merge_school }.to change(MentorAtSchoolPeriod, :count).by(-1)

            expect { mentor_period_at_predecessor.reload }.to raise_error(ActiveRecord::RecordNotFound)

            expect(mentor_period_at_successor.reload).to have_attributes(
              school: successor_school,
              started_on: Date.new(2025, 1, 1),
              finished_on: Date.new(2025, 6, 30)
            )
          end

          it "records a school merged event" do
            expect(Events::Record).to receive(:record_school_merged_event!)
              .once
              .with(school: successor_school,
                    predecessor_gias_school: gias_school,
                    successor_gias_school:,
                    happened_at: gias_school.closed_on,
                    author: an_instance_of(Events::SystemAuthor))

            merge_school
          end
        end

        context "when there are ECT periods without mentors to move" do
          let!(:ects_without_mentor) { FactoryBot.create_list(:ect_at_school_period, 2, school: predecessor_school) }

          it { expect(merge_school).to be_truthy }

          it "moves ECT periods without mentors to the successor school" do
            allow(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to receive(:call).and_call_original

            merge_school

            expect(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to have_received(:call).twice

            ects_without_mentor.each do |ect|
              expect(ect.reload.school).to eq(successor_school)
            end
          end

          it "records a school merged event" do
            expect(Events::Record).to receive(:record_school_merged_event!)
              .once
              .with(school: successor_school,
                    predecessor_gias_school: gias_school,
                    successor_gias_school:,
                    happened_at: gias_school.closed_on,
                    author: an_instance_of(Events::SystemAuthor))

            merge_school
          end

          context "when both ECTs are training with the same partnership" do
            let(:school_partnership) { FactoryBot.create(:school_partnership, school: predecessor_school, lead_provider_delivery_partnership:) }
            let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }

            before do
              ects_without_mentor.each do |ect_at_school_period|
                FactoryBot.create(:training_period, :for_ect, :with_school_partnership, ect_at_school_period:, school_partnership:)
              end
            end

            it "moves ECT periods without mentors to the successor school and creates a new partnership for the successor school" do
              allow(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to receive(:call).and_call_original

              expect { merge_school }.to change(SchoolPartnership, :count).by(1)

              expect(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to have_received(:call).twice

              ects_without_mentor.each do |ect|
                expect(ect.reload.school).to eq(successor_school)
                new_school_partnership = ect.training_periods.first.school_partnership
                expect(new_school_partnership.school).to eq(successor_school)
                expect(new_school_partnership.lead_provider_delivery_partnership).to eq(lead_provider_delivery_partnership)
              end
            end
          end
        end
      end

      context "when there are no mentors or ECTs at the predecessor school" do
        it "does not merge any periods" do
          allow(GIAS::Schools::MentorAtSchoolPeriods::Merge).to receive(:call)

          merge_school

          expect(GIAS::Schools::MentorAtSchoolPeriods::Merge).not_to have_received(:call)
        end

        it "does not move any periods" do
          allow(GIAS::Schools::MentorAtSchoolPeriods::Transfer).to receive(:call)
          allow(GIAS::Schools::ECTAtSchoolPeriods::Transfer).to receive(:call)

          merge_school

          expect(GIAS::Schools::MentorAtSchoolPeriods::Transfer).not_to have_received(:call)
          expect(GIAS::Schools::ECTAtSchoolPeriods::Transfer).not_to have_received(:call)
        end

        it "does not create any school partnerships" do
          expect { merge_school }.not_to change(SchoolPartnership, :count)
        end

        it "records a school merged event" do
          expect(Events::Record).to receive(:record_school_merged_event!)
            .once
            .with(school: successor_school,
                  predecessor_gias_school: gias_school,
                  successor_gias_school:,
                  happened_at: gias_school.closed_on,
                  author: an_instance_of(Events::SystemAuthor))

          merge_school
        end
      end
    end
  end
end
