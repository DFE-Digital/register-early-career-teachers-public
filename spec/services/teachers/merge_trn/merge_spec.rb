RSpec.describe Teachers::MergeTRN::Merge do
  subject(:service) do
    described_class.call(
      periods:,
      destination:
    )
  end

  let(:source) do
    FactoryBot.create(:teacher,
                      :merged_in_trs,
                      trn: source_trn,
                      trs_redirected_to: destination_trn)
  end

  let(:destination) { FactoryBot.create(:teacher, trn: destination_trn) }
  let(:school) { FactoryBot.create(:school) }
  let(:source_trn) { "654321" }
  let(:destination_trn) { "123456" }

  let(:author) { Events::SystemAuthor.new }

  let(:first_period) do
    FactoryBot.create(period_type,
                      *tags,
                      **source_attrs,
                      started_on: first_period_started_on,
                      finished_on: first_period_finished_on)
  end

  let(:second_period) do
    FactoryBot.create(period_type,
                      *tags,
                      **destination_attrs,
                      started_on: second_period_started_on,
                      finished_on: second_period_finished_on)
  end

  let(:source_period) { first_period }
  let(:destination_period) { second_period }

  let(:source_attrs) { { teacher: source, school: } }
  let(:destination_attrs) { { teacher: destination, school: } }
  let(:tags) { [] }
  let(:periods) { [first_period, second_period] }
  let(:period_type) { :mentor_at_school_period }
  let(:klass) { period_type.to_s.classify.constantize }
  let(:attrs) { { period_type => source_period } }

  let(:first_period_started_on) { Date.new(2025, 1, 1) }
  let(:first_period_finished_on) { Date.new(2025, 12, 31) }
  let(:second_period_started_on) { Date.new(2025, 4, 1) }
  let(:second_period_finished_on) { Date.new(2025, 9, 30) }

  shared_examples "it merges periods" do
    it "changes the start date of the second period" do
      expect { service }.to change(destination_period, :started_on).to(first_period_started_on)
    end

    it "changes the end date of the second period" do
      expect { service }.to change(destination_period, :finished_on).to(first_period_finished_on)
    end

    it "deletes the first period" do
      service

      expect(klass.exists?(first_period.id)).to be(false)
    end

    it "records an event for the periods being merged" do
      merged_period_ids = periods.map(&:id)

      service

      event = Event.where(event_type: "teacher_#{period_type.to_s.pluralize}_merged").sole
      expect(event.teacher).to eq(destination)
      expect(event.metadata["periods"].map { |p| p["id"] }).to match_array(merged_period_ids)
    end

    context "when there is an event that needs to be reassigned" do
      let!(:event) { FactoryBot.create(:event, **attrs) }

      it "changes the event to point to the destination period" do
        expect { service }.to change { event.reload.send(period_type) }.to(destination_period)
      end
    end
  end

  shared_examples "it reassigns training_periods" do
    let(:training_period_tag) { period_type == :mentor_at_school_period ? :for_mentor : :for_ect }

    context "when the training_periods do not overlap" do
      let!(:training_period) { FactoryBot.create(:training_period, *training_period_tag, **attrs) }

      it "reassigns the training_period to the destination period's teacher" do
        expect { service }.to change { training_period.send(period_type) }.to(destination_period)
      end
    end

    context "when the training_periods overlap" do
      let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2024, school:) }
      let(:training_period_attrs) { { period_type => source_period, school_partnership: } }

      let!(:training_period) do
        FactoryBot.create(:training_period,
                          *training_period_tag,
                          **training_period_attrs,
                          started_on: first_period_started_on,
                          finished_on: first_period_finished_on)
      end

      let(:overlapping_attrs) { { period_type => destination_period, school_partnership: } }

      let!(:overlapping_training_period) do
        FactoryBot.create(:training_period,
                          *training_period_tag,
                          **overlapping_attrs,
                          started_on: second_period_started_on,
                          finished_on: second_period_finished_on)
      end

      it "changes the start date of the overlapping training period" do
        service

        expect(overlapping_training_period.reload.started_on).to eq(first_period_started_on)
      end

      it "changes the end date of the overlapping training period" do
        service

        expect(overlapping_training_period.reload.finished_on).to eq(first_period_finished_on)
      end

      it "deletes the first training period" do
        service

        expect(TrainingPeriod).not_to exist(training_period.id)
      end
    end
  end

  shared_examples "it reassigns mentorship_periods" do
    context "when the mentorship_periods do not overlap" do
      let(:period_attr) { period_type == :mentor_at_school_period ? :mentor : :mentee }
      let(:other_period_attr) { period_type == :mentor_at_school_period ? :mentee : :mentor }
      let(:other_period_type) do
        case period_type
        when :mentor_at_school_period then :ect_at_school_period
        when :ect_at_school_period then :mentor_at_school_period
        end
      end

      let(:other_period) do
        FactoryBot.create(other_period_type,
                          school:,
                          started_on: first_period_started_on,
                          finished_on: first_period_finished_on)
      end

      let(:mentorship_attrs) { { period_attr => source_period, other_period_attr => other_period } }

      let!(:mentorship_period) do
        FactoryBot.create(:mentorship_period,
                          **mentorship_attrs,
                          started_on: first_period_started_on,
                          finished_on: first_period_finished_on)
      end

      it "reassigns the mentorship_period to the destination period's teacher" do
        expect { service }.to change { mentorship_period.reload.send(period_attr) }.to(destination_period)
      end
    end
  end

  shared_examples "it reassigns declarations" do
    context "when there are declarations" do
      let!(:declaration) { FactoryBot.create(:declaration, training_period: first_period) }

      it "reassigns the training_period to the destination period's teacher" do
        first_period.reload

        expect { service }.to change { declaration.reload.training_period }.to(destination_period)
      end
    end
  end

  describe "#call" do
    context "mentor at school periods" do
      let(:period_type) { :mentor_at_school_period }

      it_behaves_like "it merges periods"
      it_behaves_like "it reassigns training_periods"
      it_behaves_like "it reassigns mentorship_periods"
    end

    context "ect at school periods" do
      let(:period_type) { :ect_at_school_period }

      it_behaves_like "it merges periods"
      it_behaves_like "it reassigns training_periods"
      it_behaves_like "it reassigns mentorship_periods"
    end

    context "training periods" do
      let(:period_type) { :training_period }
      let(:tags) { [:for_ect] }

      let(:source_ect) do
        FactoryBot.create(:ect_at_school_period,
                          teacher: source,
                          school:,
                          started_on: first_period_started_on,
                          finished_on: first_period_finished_on)
      end

      let(:destination_ect) do
        FactoryBot.create(:ect_at_school_period,
                          teacher: destination,
                          school:,
                          started_on: first_period_started_on,
                          finished_on: first_period_finished_on)
      end

      let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2024) }
      let(:source_attrs) { { ect_at_school_period: source_ect, school_partnership: } }
      let(:destination_attrs) { { ect_at_school_period: destination_ect, school_partnership: } }

      it_behaves_like "it merges periods"
      it_behaves_like "it reassigns declarations"

      context "when the periods are for different partnerships" do
        let(:other_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2024) }
        let(:destination_attrs) { { ect_at_school_period: destination_ect, school_partnership: other_school_partnership } }
        let(:source_attrs) { { ect_at_school_period: source_ect, school_partnership: } }

        it "raises a CannotMergePeriods error" do
          expect { service }.to raise_error(Teachers::MergeTRN::Merge::CannotMergePeriods, "Periods have different partnerships")
        end
      end

      context "when the periods have different training programmes" do
        let(:tags) { %i[for_ect with_only_expression_of_interest] }

        let(:destination_attrs) { { ect_at_school_period: destination_ect, training_programme: :school_led, expression_of_interest: nil, schedule: nil } }
        let(:source_attrs) { { ect_at_school_period: source_ect } }

        it "raises a CannotMergePeriods error" do
          expect { service }.to raise_error(Teachers::MergeTRN::Merge::CannotMergePeriods, "Periods have different training programmes")
        end
      end

      context "when the periods have different schedules" do
        let(:tags) { %i[for_ect with_schedule] }
        let(:lead_provider) { school_partnership.lead_provider }
        let(:delivery_partner) { school_partnership.delivery_partner }
        let(:other_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2023, lead_provider:, delivery_partner:) }
        let(:destination_attrs) { { ect_at_school_period: destination_ect, school_partnership: other_school_partnership } }

        it "raises a CannotMergePeriods error" do
          expect { service }.to raise_error(Teachers::MergeTRN::Merge::CannotMergePeriods, "Periods have different schedules")
        end
      end
    end
  end

  def max_date
    dates = [first_period_finished_on, second_period_finished_on]

    return nil if dates.any?(&:nil?)

    dates.compact.max
  end
end
