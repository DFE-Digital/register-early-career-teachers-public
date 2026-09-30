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
                      teacher: source,
                      school:,
                      started_on: first_period_started_on,
                      finished_on: first_period_finished_on)
  end

  let(:second_period) do
    FactoryBot.create(period_type,
                      teacher: destination,
                      school:,
                      started_on: second_period_started_on,
                      finished_on: second_period_finished_on)
  end

  let(:source_period) { first_period }
  let(:destination_period) { second_period }

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
    context "when the training_periods do not overlap" do
      let(:for_period) do
        case period_type
        when :mentor_at_school_period then :for_mentor
        when :ect_at_school_period then :for_ect
        end
      end
      let!(:training_period) { FactoryBot.create(:training_period, for_period, **attrs) }

      it "reassigns the training_period to the destination period's teacher" do
        expect { service }.to change { training_period.send(period_type) }.to(destination_period)
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
  end

  def max_date
    dates = [first_period_finished_on, second_period_finished_on]

    return nil if dates.any?(&:nil?)

    dates.compact.max
  end
end
