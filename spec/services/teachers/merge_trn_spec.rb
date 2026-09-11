RSpec.describe Teachers::MergeTRN do
  subject(:service) do
    described_class.new(teacher:)
  end

  let(:teacher) do
    FactoryBot.create(:teacher,
                      :merged_in_trs,
                      trn: source_trn,
                      trs_redirected_to: destination_trn)
  end

  let!(:destination) { FactoryBot.create(:teacher, :with_realistic_name, trn: destination_trn) }

  let(:source_trn) { "654321" }
  let(:destination_trn) { "123456" }

  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: first_period_started_on, finished_on: first_period_finished_on) }
  let!(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, :with_framework_agreement, ect_at_school_period:, started_on: first_period_started_on, finished_on: first_period_finished_on) }
  let!(:ect_declaration) { FactoryBot.create(:declaration, training_period: ect_training_period) }

  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: first_period_started_on, finished_on: first_period_finished_on) }
  let!(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_framework_agreement, mentor_at_school_period:, started_on: first_period_started_on, finished_on: first_period_finished_on) }
  let!(:mentor_declaration) { FactoryBot.create(:declaration, training_period: mentor_training_period) }

  let!(:destination_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: destination, started_on: second_period_started_on, finished_on: second_period_finished_on) }
  let!(:destination_mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_framework_agreement, mentor_at_school_period: destination_mentor_at_school_period, started_on: second_period_started_on, finished_on: second_period_finished_on) }
  let!(:destination_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: destination, started_on: second_period_started_on, finished_on: second_period_finished_on) }
  let!(:destination_ect_training_period) { FactoryBot.create(:training_period, :for_ect, :with_framework_agreement, ect_at_school_period: destination_ect_at_school_period, started_on: second_period_started_on, finished_on: second_period_finished_on) }

  let!(:induction_period) { FactoryBot.create(:induction_period, teacher:) }
  let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher:) }

  let(:first_period_started_on) { Date.new(2025, 1, 1) }
  let(:first_period_finished_on) { Date.new(2025, 3, 31) }
  let(:second_period_started_on) { Date.new(2025, 6, 1) }
  let(:second_period_finished_on) { Date.new(2025, 11, 30) }

  shared_examples "does not move or change any data" do
    it "does not move any ect_at_school_periods" do
      expect { service.merge! }.not_to(change { teacher.reload.ect_at_school_periods.map(&:teacher_id) })
    end

    it "does not move any mentor_at_school_periods" do
      expect { service.merge! }.not_to(change { teacher.reload.mentor_at_school_periods.map(&:teacher_id) })
    end

    it "does not move any induction periods" do
      expect { service.merge! }.not_to(change { teacher.reload.induction_periods.map(&:teacher_id) })
    end

    it "does not move any induction extensions" do
      expect { service.merge! }.not_to(change { teacher.reload.induction_extensions.map(&:teacher_id) })
    end

    it "does not move any declarations or training periods" do
      expect { service.merge! }.not_to(change { ect_declaration.reload.training_period.teacher })
    end

    it "does not move any mentor declarations or training periods" do
      expect { service.merge! }.not_to(change { mentor_declaration.reload.training_period.teacher })
    end

    it "does not record a TeacherIdChange" do
      expect { service.merge! }.not_to change(TeacherIdChange, :count)
    end

    it "does not remove any metadata" do
      expect { service.merge! }.not_to(change { teacher.reload.lead_provider_metadata.count })
    end

    it "does not destroy the source teacher" do
      expect { service.merge! }.not_to(change { Teacher.exists?(teacher.id) })
    end
  end

  describe "#merge!" do
    context "when the destination has no overlapping records" do
      it "moves the at-school periods to the destination teacher" do
        service.merge!

        expect(ect_at_school_period.reload.teacher).to eq(destination)
        expect(mentor_at_school_period.reload.teacher).to eq(destination)
      end

      it "leaves the destinations teacher's periods in place" do
        service.merge!

        expect(destination.reload.ect_at_school_periods).to contain_exactly(ect_at_school_period, destination_ect_at_school_period)
        expect(destination.mentor_at_school_periods).to contain_exactly(mentor_at_school_period, destination_mentor_at_school_period)
        expect(destination.mentor_training_periods).to contain_exactly(mentor_training_period, destination_mentor_training_period)
        expect(destination.ect_training_periods).to contain_exactly(ect_training_period, destination_ect_training_period)
      end

      it "moves the induction records to the destination teacher" do
        service.merge!

        expect(induction_period.reload.teacher).to eq(destination)
        expect(induction_extension.reload.teacher).to eq(destination)
      end

      it "moves the declarations with their training periods to the destination teacher" do
        service.merge!

        expect(ect_declaration.reload.training_period.teacher).to eq(destination)
        expect(mentor_declaration.reload.training_period.teacher).to eq(destination)
      end

      it "records a TeacherIdChange from the source participant to the destination participant" do
        source_api_id = teacher.api_id

        expect { service.merge! }.to change(TeacherIdChange, :count).by(1)

        change = TeacherIdChange.last
        expect(change.teacher).to eq(destination)
        expect(change.api_from_teacher_id).to eq(source_api_id)
        expect(change.api_to_teacher_id).to eq(destination.api_id)
      end

      it "moves the source's existing teacher_id_changes onto the destination" do
        earlier_change = FactoryBot.create(:teacher_id_change, teacher:)

        service.merge!

        expect(earlier_change.reload.teacher).to eq(destination)
      end

      it "populates the destination's metadata (which the model hooks do not do on reassignment)" do
        expect { service.merge! }.to change { destination.reload.lead_provider_metadata.count }.from(0)
      end

      it "records a merge event" do
        allow(Events::Record).to receive(:record_teacher_trn_merged_events!).and_call_original

        service.merge!

        expect(Events::Record).to have_received(:record_teacher_trn_merged_events!)
          .with(author: an_instance_of(Events::SystemAuthor), source: teacher, destination:)
      end

      it "calls a sync with TRS" do
        expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later)

        service.merge!
      end
    end

    context "when the teacher is not permanent redirect" do
      let(:teacher) { FactoryBot.create(:teacher, :with_realistic_name, trn: source_trn, trs_redirected_to: destination_trn) }

      it_behaves_like "does not move or change any data"

      it "does not record a merge event" do
        expect(Events::Record).not_to receive(:record_teacher_trn_merged_events!)

        service.merge!
      end

      it "does not resync with TRS" do
        expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later)

        service.merge!
      end
    end

    context "when the teacher has no redirect id" do
      let(:teacher) { FactoryBot.create(:teacher, :with_realistic_name, :merged_in_trs, trn: source_trn, trs_redirected_to: nil) }

      it_behaves_like "does not move or change any data"

      it "does not record a merge event" do
        expect(Events::Record).not_to receive(:record_teacher_trn_merged_events!)
        service.merge!
      end

      it "does not resync with TRS" do
        expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later)

        service.merge!
      end
    end

    context "when the destination has an overlapping period" do
      let(:second_period_started_on) { Date.new(2025, 3, 1) }

      it_behaves_like "does not move or change any data"

      it "does not record a merge event" do
        expect(Events::Record).not_to receive(:record_teacher_trn_merged_events!)

        service.merge!
      end

      it "does not resync with TRS" do
        expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later)

        service.merge!
      end
    end
  end
end
