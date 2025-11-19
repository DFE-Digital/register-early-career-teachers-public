module ECTAtSchoolPeriods
  describe SwitchMentor do
    subject(:switch_mentor) do
      SwitchMentor.switch(
        ect_at_school_period,
        to: selected_mentor_at_school_period,
        author:,
        lead_provider:
      )
    end

    let(:contract_period) { FactoryBot.create(:contract_period, :current, :with_schedules) }
    let(:author) do
      FactoryBot.create(:school_user, school_urn: ect_at_school_period.school.urn)
    end

    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 2.weeks.ago)
    end

    let(:selected_mentor_teacher) { FactoryBot.create(:teacher) }
    let(:selected_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        school: ect_at_school_period.school,
        teacher: selected_mentor_teacher,
        started_on: ect_at_school_period.started_on - 1.month
      )
    end

    describe ".switch" do
      context "when the ECT is undergoing school-led training" do
        let!(:ect_training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :school_led,
            :for_ect,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end
        let(:lead_provider) { nil }

        it "assigns a mentor" do
          expect { switch_mentor }.to change(MentorshipPeriod, :count).by(1)

          ect_at_school_period.reload
          expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
            .to eq(selected_mentor_at_school_period)
        end

        it "does not create a training period" do
          expect { switch_mentor }.not_to change(TrainingPeriod, :count)
        end

        it "does not record a `teacher_starts_training_period` event" do
          allow(Events::Record)
            .to receive(:record_teacher_starts_training_period_event!)

          switch_mentor

          expect(Events::Record)
            .not_to have_received(:record_teacher_starts_training_period_event!)
        end
      end

      context "when the ECT is undergoing provider-led training" do
        let!(:ect_training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :provider_led,
            :for_ect,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end
        let(:lead_provider) { ect_training_period.lead_provider }

        before do
          ect_training_period.active_lead_provider.update!(contract_period:)
        end

        context "when the mentor has a provider-led training period" do
          let!(:selected_mentor_training_period) do
            FactoryBot.create(
              :training_period,
              :ongoing,
              :provider_led,
              :for_mentor,
              mentor_at_school_period: selected_mentor_at_school_period,
              started_on: selected_mentor_at_school_period.started_on
            )
          end

          it "assigns a mentor" do
            expect { switch_mentor }.to change(MentorshipPeriod, :count).by(1)

            ect_at_school_period.reload
            expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
              .to eq(selected_mentor_at_school_period)
          end

          it "does not create a training period" do
            expect { switch_mentor }.not_to change(TrainingPeriod, :count)
          end

          it "does not record a `teacher_starts_training_period` event" do
            allow(Events::Record)
              .to receive(:record_teacher_starts_training_period_event!)

            switch_mentor

            expect(Events::Record)
              .not_to have_received(:record_teacher_starts_training_period_event!)
          end
        end

        context "when the mentor is ineligible for funding" do
          let(:selected_mentor_teacher) do
            FactoryBot.create(:teacher, :ineligible_for_mentor_funding)
          end

          it "assigns a mentor" do
            expect { switch_mentor }.to change(MentorshipPeriod, :count).by(1)

            ect_at_school_period.reload
            expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
              .to eq(selected_mentor_at_school_period)
          end

          it "does not create a training period" do
            expect { switch_mentor }.not_to change(TrainingPeriod, :count)
          end

          it "does not record a `teacher_starts_training_period` event" do
            allow(Events::Record)
              .to receive(:record_teacher_starts_training_period_event!)

            switch_mentor

            expect(Events::Record)
              .not_to have_received(:record_teacher_starts_training_period_event!)
          end
        end

        context "when the mentor is eligible for funding" do
          it "assigns a mentor" do
            expect { switch_mentor }.to change(MentorshipPeriod, :count).by(1)

            ect_at_school_period.reload
            expect(ect_at_school_period.current_or_next_mentorship_period.mentor)
              .to eq(selected_mentor_at_school_period)
          end

          it "creates a training period" do
            expect { switch_mentor }.to change(TrainingPeriod, :count).by(1)

            new_training_period = TrainingPeriod.last
            expect(selected_mentor_at_school_period.training_periods)
              .to contain_exactly(new_training_period)
            expect(new_training_period.lead_provider)
              .to eq(ect_training_period.lead_provider)
          end

          it 'assigns the correct schedule to the new training period' do
            travel_to(Date.new(2025, 9, 1)) do
              switch_mentor

              new_training_period = TrainingPeriod.last

              expect(new_training_period.schedule.identifier).to eq('ecf-standard-september')
              expect(new_training_period.schedule.contract_period_year).to eq(2025)
            end
          end

          it "records a `teacher_starts_training_period` event" do
            allow(Events::Record)
              .to receive(:record_teacher_starts_training_period_event!)

            switch_mentor

            expect(Events::Record)
              .to have_received(:record_teacher_starts_training_period_event!)
          end
        end
      end
    end
  end
end
