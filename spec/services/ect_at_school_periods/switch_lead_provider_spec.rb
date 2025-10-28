module ECTAtSchoolPeriods
  describe SwitchLeadProvider do
    subject(:switch_lead_provider) do
      SwitchLeadProvider.switch(
        ect_at_school_period,
        to: lead_provider,
        from: current_lead_provider,
        author:
      )
    end

    let(:contract_period) { FactoryBot.create(:contract_period, :current) }
    let(:author) do
      FactoryBot.create(:school_user, school_urn: ect_at_school_period.school.urn)
    end

    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 2.weeks.ago)
    end

    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:active_lead_provider) do
      FactoryBot.create(
        :active_lead_provider,
        lead_provider:,
        contract_period:
      )
    end

    let(:current_lead_provider) { FactoryBot.create(:lead_provider) }
    let(:current_active_lead_provider) do
      FactoryBot.create(
        :active_lead_provider,
        lead_provider: current_lead_provider,
        contract_period:
      )
    end

    context "when there is an existing school partnership" do
      let(:lead_provider_delivery_partnership) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: current_active_lead_provider
        )
      end
      let(:school_partnership) do
        FactoryBot.create(
          :school_partnership,
          lead_provider_delivery_partnership:,
          school: ect_at_school_period.school
        )
      end
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :ongoing,
          :provider_led,
          :with_school_partnership,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          school_partnership:
        )
      end

      context "when the date of transition is today" do
        it "finishes the existing training period" do
          freeze_time

          switch_lead_provider

          expect { training_period.reload }.not_to raise_error
          expect(training_period.finished_on).to eq(Date.current)
        end

        it "creates a new training period with the new lead provider" do
          switch_lead_provider

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(Date.current)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          switch_lead_provider
        end
      end

      context "when the date of transition is in the future" do
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :ongoing,
            started_on: 1.month.from_now
          )
        end

        it "destroys the existing training period" do
          freeze_time

          switch_lead_provider

          expect { training_period.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it "creates a new training period" do
          switch_lead_provider

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(ect_at_school_period.started_on)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          switch_lead_provider
        end
      end
    end

    context "when there is no existing school partnership" do
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :ongoing,
          :provider_led,
          :with_only_expression_of_interest,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          expression_of_interest: current_active_lead_provider
        )
      end

      context "when the date of transition is today" do
        it "destroys the existing training period" do
          freeze_time

          switch_lead_provider

          expect { training_period.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it "creates a new training period" do
          switch_lead_provider

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(Date.current)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.expression_of_interest.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          switch_lead_provider
        end
      end

      context "when the date of transition is in the future" do
        let(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :ongoing,
            started_on: 1.month.from_now
          )
        end

        it "destroys the existing training period" do
          freeze_time

          switch_lead_provider

          expect { training_period.reload }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it "creates a new training period" do
          switch_lead_provider

          new_training_period = ect_at_school_period.reload.current_or_next_training_period
          expect(new_training_period.started_on).to eq(ect_at_school_period.started_on)
          expect(new_training_period.expression_of_interest.lead_provider)
            .to eq(lead_provider)
        end

        it "records a `teacher_training_lead_provider_updated` event" do
          freeze_time
          old_lead_provider = training_period.expression_of_interest.lead_provider

          expect(Events::Record)
            .to receive(:record_teacher_training_lead_provider_updated_event!)
            .with(
              old_lead_provider_name: old_lead_provider.name,
              new_lead_provider_name: lead_provider.name,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )

          switch_lead_provider
        end
      end

      context "when the ECT is on a school-led programme" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :ongoing,
            :school_led,
            ect_at_school_period:,
            started_on: ect_at_school_period.started_on
          )
        end

        it "raises and does not mutate state" do
          expect {
            switch_lead_provider
          }.to raise_error(ECTAtSchoolPeriods::SwitchLeadProvider::SchoolLedTrainingProgrammeError)

          expect { training_period.reload }.not_to raise_error
          expect(training_period.finished_on).to be_nil
        end
      end
    end
  end
end
