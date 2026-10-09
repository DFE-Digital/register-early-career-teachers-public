RSpec.shared_context "a teacher merged in TRS" do
  let(:source) do
    FactoryBot.create(
      :teacher,
      :merged_in_trs,
      trn: source_trn,
      trs_redirected_to: destination_trn
    )
  end

  let!(:destination) { FactoryBot.create(:teacher, trn: destination_trn) }

  let(:source_trn) { "654321" }
  let(:destination_trn) { "123456" }
end

RSpec.shared_context "a mergeable period" do
  include_context "a teacher merged in TRS"

  let(:school) { FactoryBot.create(:school) }

  let(:source_period) { first_period }
  let(:destination_period) { second_period }

  let(:periods) { [first_period, second_period] }
  let(:klass) { period_type.to_s.classify.constantize }
  let(:attrs) { { period_type => source_period } }

  let(:source_attrs) { { teacher: source, school: } }
  let(:destination_attrs) { { teacher: destination, school: } }

  let(:first_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **source_attrs,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let(:second_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **destination_attrs,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let(:first_period_started_on) { Date.new(2025, 1, 1) }
  let(:first_period_finished_on) { Date.new(2025, 12, 31) }
  let(:second_period_started_on) { Date.new(2025, 4, 1) }
  let(:second_period_finished_on) { Date.new(2025, 9, 30) }

  let(:author) { Events::SystemAuthor.new }
end

RSpec.shared_context "overlapping periods" do
  include_context "a teacher merged in TRS"

  let(:school) { FactoryBot.create(:school) }
  let(:other_school) { FactoryBot.create(:school) }
  let(:other_source_attrs) { { teacher: source, school: other_school } }
  let(:other_destination_attrs) { { teacher: destination, school: other_school } }

  let(:source_attrs) { { teacher: source, school: } }
  let(:destination_attrs) { { teacher: destination, school: } }

  let(:first_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **source_attrs,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let(:second_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **destination_attrs,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let(:third_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **source_attrs,
      started_on: third_period_started_on,
      finished_on: third_period_finished_on
    )
  end

  let(:fourth_period) do
    FactoryBot.create(
      period_type,
      *tags,
      **destination_attrs,
      started_on: fourth_period_started_on,
      finished_on: fourth_period_finished_on
    )
  end

  let(:first_period_started_on) { Date.new(2025, 1, 1) }
  let(:first_period_finished_on) { Date.new(2025, 3, 31) }
  let(:second_period_started_on) { Date.new(2025, 3, 1) }
  let(:second_period_finished_on) { Date.new(2025, 6, 30) }
  let(:third_period_started_on) { Date.new(2025, 7, 1) }
  let(:third_period_finished_on) { Date.new(2025, 9, 30) }
  let(:fourth_period_started_on) { Date.new(2025, 9, 1) }
  let(:fourth_period_finished_on) { Date.new(2025, 12, 31) }
end

RSpec.shared_examples "it merges periods" do
  context "it merges overlapping periods" do
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
end

RSpec.shared_examples "it moves non-overlapping training_periods" do
  context "when the training_periods do not overlap" do
    let(:training_period_tag) { period_type == :mentor_at_school_period ? :for_mentor : :for_ect }
    let!(:training_period) { FactoryBot.create(:training_period, *training_period_tag, **attrs) }

    it "reassigns the training_period to the destination period's teacher" do
      expect { service }.to change { training_period.reload.send(period_type) }.to(destination_period)
    end

    it "does not call the Merge service" do
      expect(Teachers::MergeTRN::TrainingPeriods::Merge).not_to receive(:call)
      service
    end
  end
end

RSpec.shared_examples "it merges overlapping training periods" do
  context "when the training_periods overlap" do
    let(:training_period_tag) { period_type == :mentor_at_school_period ? :for_mentor : :for_ect }
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

    it "calls the Merge service for overlapping training periods" do
      allow(Teachers::MergeTRN::TrainingPeriods::Overlapping).to receive(:find).and_call_original

      expect(Teachers::MergeTRN::TrainingPeriods::Merge).to receive(:call).with(
        periods: contain_exactly(training_period, overlapping_training_period),
        destination:
      )

      service

      expect(Teachers::MergeTRN::TrainingPeriods::Overlapping).to have_received(:find).with(
        periods: contain_exactly(training_period, overlapping_training_period)
      )
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

RSpec.shared_examples "it moves non-overlapping mentorship_periods" do
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

    it "does not call the Merge service for overlapping mentorship periods" do
      expect(Teachers::MergeTRN::MentorshipPeriods::Merge).not_to receive(:call)
      service
    end
  end
end

RSpec.shared_examples "it identifies overlapping periods" do
  let(:periods) { [first_period, second_period] }
  let(:third_period_started_on) { first_period_started_on }
  let(:third_period_finished_on) { first_period_finished_on }
  let(:fourth_period_started_on) { second_period_started_on }
  let(:fourth_period_finished_on) { second_period_finished_on }

  context "when two periods overlap" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 3, 1) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }

    it { is_expected.to eq([[first_period, second_period]]) }
  end

  context "when two periods are adjacent" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 4, 1) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }

    it { is_expected.to be_empty }
  end

  context "when two periods have a gap" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 4, 2) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }

    it { is_expected.to be_empty }
  end

  context "when three periods overlap transitively" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 3, 1) }
    let(:second_period_finished_on) { Date.new(2025, 11, 30) }
    let(:third_period_started_on) { Date.new(2025, 11, 1) }
    let(:third_period_finished_on) { Date.new(2025, 12, 31) }

    let(:periods) { [first_period, second_period, third_period] }

    it { is_expected.to eq([[first_period, second_period, third_period]]) }
  end

  context "when two periods overlap but a third period is separate" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 3, 1) }
    let(:second_period_finished_on) { Date.new(2025, 11, 30) }
    let(:third_period_started_on) { Date.new(2025, 12, 15) }
    let(:third_period_finished_on) { Date.new(2025, 12, 31) }

    let(:periods) { [first_period, second_period, third_period] }

    it { is_expected.to eq([[first_period, second_period]]) }
  end

  context "when there are two separate groups of overlapping periods" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { Date.new(2025, 3, 31) }
    let(:second_period_started_on) { Date.new(2025, 3, 15) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }
    let(:third_period_started_on) { Date.new(2025, 7, 15) }
    let(:third_period_finished_on) { Date.new(2025, 9, 30) }
    let(:fourth_period_started_on) { Date.new(2025, 9, 1) }
    let(:fourth_period_finished_on) { Date.new(2025, 12, 31) }

    let(:periods) { [first_period, second_period, third_period, fourth_period] }

    it "returns two separate merge groups" do
      expect(subject).to eq([
        [first_period, second_period],
        [third_period, fourth_period]
      ])
    end
  end

  context "when the earliest period is ongoing" do
    let(:first_period_started_on) { Date.new(2025, 1, 1) }
    let(:first_period_finished_on) { nil }
    let(:second_period_started_on) { Date.new(2025, 4, 1) }
    let(:second_period_finished_on) { Date.new(2025, 6, 30) }
    let(:fourth_period_finished_on) { nil }
    let(:first_period_number_of_terms) { nil }

    it { is_expected.to eq([[first_period, second_period]]) }
  end
end

RSpec.shared_examples "it guards against invalid periods" do
  context "when no periods are present" do
    let(:periods) { [] }

    it { is_expected.to be_empty }
  end

  context "when the periods are of the wrong type" do
    let(:second_period) { FactoryBot.create(other_period_types.sample) }
    let(:other_period_types) { %i[mentor_at_school_period ect_at_school_period training_period mentorship_period].excluding(period_type) }

    let(:periods) { [first_period, second_period] }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end

RSpec.shared_examples "it identifies overlapping at_school periods" do
  context "when there are periods at two schools" do
    let(:third_period) do
      FactoryBot.create(period_type,
                        *tags,
                        **other_source_attrs,
                        started_on: third_period_started_on,
                        finished_on: third_period_finished_on)
    end

    let(:fourth_period) do
      FactoryBot.create(
        period_type,
        *tags,
        **other_destination_attrs,
        started_on: fourth_period_started_on,
        finished_on: fourth_period_finished_on
      )
    end

    let(:periods) { [first_period, second_period, third_period, fourth_period] }

    context "when periods at both schools overlap" do
      it "the overlapping groups at each school" do
        expect(subject).to eq([
          [first_period, second_period],
          [third_period, fourth_period]
        ])
      end
    end

    context "when there are no overlapping periods at the first school" do
      let(:second_period_started_on) { Date.new(2025, 4, 2) }

      it "does not include periods from the first school" do
        expect(subject).to eq([[third_period, fourth_period]])
      end
    end

    context "when there are no overlapping periods at the second school" do
      let(:fourth_period_started_on) { Date.new(2025, 11, 1) }

      it "does not include periods from the second school" do
        expect(subject).to eq([[first_period, second_period]])
      end
    end

    context "when there are no overlapping periods at either school" do
      let(:second_period_started_on) { Date.new(2025, 4, 2) }
      let(:fourth_period_started_on) { Date.new(2025, 11, 1) }

      it "does not include periods from either school" do
        expect(subject).to be_empty
      end
    end
  end
end
