describe Schools::PopulatePreviousChoices do
  subject(:service) { described_class.new }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
  let(:school) { FactoryBot.create(:school, :state_funded) }

  describe "#call" do
    context "when a school has a school-led ECT with an appropriate body" do
      let!(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :finished,
          school:,
          school_reported_appropriate_body: appropriate_body
        )
      end
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          finished_on: ect_at_school_period.finished_on
        )
      end

      before do
        service.call
        school.reload
      end

      it "sets last_chosen_appropriate_body to the appropriate body" do
        expect(school.last_chosen_appropriate_body).to eq(appropriate_body)
      end

      it "sets last_chosen_training_programme to school_led" do
        expect(school.last_chosen_training_programme).to eq("school_led")
      end

      it "does not set last_chosen_lead_provider" do
        expect(school.last_chosen_lead_provider).to be_nil
      end
    end

    context "when a school has a provider-led ECT with an appropriate body" do
      let!(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :finished,
          school:,
          school_reported_appropriate_body: appropriate_body
        )
      end
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :provider_led,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          finished_on: ect_at_school_period.finished_on
        )
      end

      before do
        service.call
        school.reload
      end

      it "sets last_chosen_appropriate_body to the appropriate body" do
        expect(school.last_chosen_appropriate_body).to eq(appropriate_body)
      end

      it "sets last_chosen_training_programme to provider_led" do
        expect(school.last_chosen_training_programme).to eq("provider_led")
      end

      it "sets last_chosen_lead_provider to the training period's lead provider" do
        expect(school.last_chosen_lead_provider).to eq(training_period.lead_provider)
      end
    end

    context "when a school has multiple ECTs" do
      let(:older_appropriate_body) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
      let(:newer_appropriate_body) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }

      let!(:older_ect) do
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          school_reported_appropriate_body: older_appropriate_body
        )
      end
      let!(:older_training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period: older_ect,
          started_on: older_ect.started_on,
          finished_on: older_ect.finished_on
        )
      end

      let!(:newer_ect) do
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          started_on: 6.months.ago,
          finished_on: 1.month.ago,
          school_reported_appropriate_body: newer_appropriate_body
        )
      end
      let!(:newer_training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period: newer_ect,
          started_on: newer_ect.started_on,
          finished_on: newer_ect.finished_on
        )
      end

      before do
        service.call
        school.reload
      end

      it "uses the most recently started ECT's choices" do
        expect(school.last_chosen_appropriate_body).to eq(newer_appropriate_body)
      end
    end

    context "when a school already has previous choices set" do
      let(:last_chosen_appropriate_body) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
      let(:school) do
        FactoryBot.create(
          :school,
          :state_funded,
          :school_led_last_chosen,
          last_chosen_appropriate_body:
        )
      end
      let!(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :finished,
          school:,
          school_reported_appropriate_body: appropriate_body
        )
      end
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          finished_on: ect_at_school_period.finished_on
        )
      end

      before do
        service.call
        school.reload
      end

      it "does not overwrite existing choices" do
        expect(school.last_chosen_appropriate_body).to eq(last_chosen_appropriate_body)
      end
    end

    context "when a school has ECTs but none with an appropriate body" do
      let!(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :finished,
          school:,
          school_reported_appropriate_body: nil
        )
      end
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          finished_on: ect_at_school_period.finished_on
        )
      end

      before do
        service.call
        school.reload
      end

      it "does not set choices on the school" do
        expect(school.last_chosen_appropriate_body).to be_nil
        expect(school.last_chosen_training_programme).to be_nil
      end
    end

    context "when the most recent ECT has no appropriate body but an older one does" do
      let!(:older_ect) do
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          started_on: 2.years.ago,
          finished_on: 1.year.ago,
          school_reported_appropriate_body: appropriate_body
        )
      end
      let!(:older_training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period: older_ect,
          started_on: older_ect.started_on,
          finished_on: older_ect.finished_on
        )
      end

      let!(:newer_ect) do
        FactoryBot.create(
          :ect_at_school_period,
          school:,
          started_on: 6.months.ago,
          finished_on: 1.month.ago,
          school_reported_appropriate_body: nil
        )
      end
      let!(:newer_training_period) do
        FactoryBot.create(
          :training_period,
          :school_led,
          ect_at_school_period: newer_ect,
          started_on: newer_ect.started_on,
          finished_on: newer_ect.finished_on
        )
      end

      before do
        service.call
        school.reload
      end

      it "uses the most recent ECT with an appropriate body" do
        expect(school.last_chosen_appropriate_body).to eq(appropriate_body)
      end
    end

    context "when a school has no ECTs" do
      before do
        school
        service.call
        school.reload
      end

      it "does not set choices on the school" do
        expect(school.last_chosen_appropriate_body).to be_nil
        expect(school.last_chosen_training_programme).to be_nil
      end
    end

    context "when an ECT has no training periods" do
      let!(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :finished,
          school:,
          school_reported_appropriate_body: appropriate_body
        )
      end

      before do
        service.call
        school.reload
      end

      it "does not set choices on the school" do
        expect(school.last_chosen_appropriate_body).to be_nil
        expect(school.last_chosen_training_programme).to be_nil
      end
    end

    context "when processing multiple schools" do
      let(:school_a) { FactoryBot.create(:school, :state_funded) }
      let(:school_b) { FactoryBot.create(:school, :state_funded) }
      let(:ab_a) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
      let(:ab_b) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }

      let!(:ect_a) do
        FactoryBot.create(
          :ect_at_school_period, :finished,
          school: school_a,
          school_reported_appropriate_body: ab_a
        )
      end

      let!(:training_a) do
        FactoryBot.create(
          :training_period, :school_led,
          ect_at_school_period: ect_a,
          started_on: ect_a.started_on,
          finished_on: ect_a.finished_on
        )
      end

      let!(:ect_b) do
        FactoryBot.create(
          :ect_at_school_period, :finished,
          school: school_b,
          school_reported_appropriate_body: ab_b
        )
      end

      let!(:training_b) do
        FactoryBot.create(
          :training_period, :school_led,
          ect_at_school_period: ect_b,
          started_on: ect_b.started_on,
          finished_on: ect_b.finished_on
        )
      end

      before do
        service.call
        school_a.reload
        school_b.reload
      end

      it "updates each school independently" do
        expect(school_a.last_chosen_appropriate_body).to eq(ab_a)
        expect(school_b.last_chosen_appropriate_body).to eq(ab_b)
      end
    end
  end
end
