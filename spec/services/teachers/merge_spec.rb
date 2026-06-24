RSpec.describe Teachers::Merge do
  subject(:service) do
    described_class.new(author:, source:, destination:)
  end

  let(:author) { Events::SystemAuthor.new }
  let(:source) { FactoryBot.create(:teacher, :with_realistic_name) }
  let(:destination) { FactoryBot.create(:teacher, :with_realistic_name) }

  describe "#merge!" do
    context "when the destination has no conflicting records (clean merge)" do
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: source) }
      let!(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, :with_active_lead_provider, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: nil) }
      let!(:ect_declaration) { FactoryBot.create(:declaration, training_period: ect_training_period) }

      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: source) }
      let!(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, :with_active_lead_provider, mentor_at_school_period:, started_on: mentor_at_school_period.started_on, finished_on: nil) }
      let!(:mentor_declaration) { FactoryBot.create(:declaration, training_period: mentor_training_period) }

      let!(:induction_period) { FactoryBot.create(:induction_period, teacher: source) }
      let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher: source) }

      it "returns the destination teacher" do
        expect(service.merge!).to eq(destination)
      end

      it "moves the at-school periods to the destination teacher" do
        service.merge!

        expect(ect_at_school_period.reload.teacher).to eq(destination)
        expect(mentor_at_school_period.reload.teacher).to eq(destination)
        expect(source.reload.ect_at_school_periods).to be_empty
        expect(source.mentor_at_school_periods).to be_empty
      end

      it "moves the induction records to the destination teacher" do
        service.merge!

        expect(induction_period.reload.teacher).to eq(destination)
        expect(induction_extension.reload.teacher).to eq(destination)
        expect(source.reload.induction_periods).to be_empty
        expect(source.induction_extensions).to be_empty
      end

      it "moves the declarations with their training periods to the destination teacher" do
        service.merge!

        expect(ect_declaration.reload.training_period.teacher).to eq(destination)
        expect(mentor_declaration.reload.training_period.teacher).to eq(destination)
      end

      it "anonymises the source teacher" do
        anonymiser = instance_double(Teachers::Anonymise, anonymise!: true)
        allow(Teachers::Anonymise).to receive(:new).with(teacher: source, reason: :teacher_record_merged).and_return(anonymiser)

        service.merge!

        expect(anonymiser).to have_received(:anonymise!)
      end

      it "retains the source teacher's api_id (the recorded id-change maps back to it)" do
        expect { service.merge! }.not_to(change { source.reload.api_id })
      end

      it "records a TeacherIdChange from the source participant to the destination participant" do
        source_api_id = source.api_id

        expect { service.merge! }.to change(TeacherIdChange, :count).by(1)

        change = TeacherIdChange.last
        expect(change.teacher).to eq(destination)
        expect(change.api_from_teacher_id).to eq(source_api_id)
        expect(change.api_to_teacher_id).to eq(destination.api_id)
      end

      it "moves the source's existing teacher_id_changes onto the destination" do
        earlier_change = FactoryBot.create(:teacher_id_change, teacher: source)

        service.merge!

        expect(earlier_change.reload.teacher).to eq(destination)
      end

      it "surfaces the old participant id on the destination so API consumers can follow it" do
        lead_provider = FactoryBot.create(:lead_provider)
        source_api_id = source.api_id

        service.merge!

        response = JSON.parse(API::TeacherSerializer.render(destination.reload, lead_provider_id: lead_provider.id))
        expect(response["attributes"]["participant_id_changes"]).to include(
          a_hash_including("from_participant_id" => source_api_id, "to_participant_id" => destination.api_id)
        )
      end

      it "populates the destination's metadata (which the model hooks do not do on reassignment)" do
        expect { service.merge! }.to change { destination.reload.lead_provider_metadata.count }.from(0)
      end

      it "tears down the source's now-stale metadata (which the model hooks leave behind)" do
        Metadata::Manager.new.refresh_metadata!([source])
        expect(source.lead_provider_metadata.reload).not_to be_empty

        expect { service.merge! }.to change { source.reload.lead_provider_metadata.count }.to(0)
      end

      it "records the merge events before anonymising" do
        allow(Events::Record).to receive(:record_teacher_merged_events!).and_call_original

        service.merge!

        expect(Events::Record).to have_received(:record_teacher_merged_events!)
          .with(author:, source:, destination:, body: nil, zendesk_ticket_id: nil)
      end
    end

    context "when the destination already has an overlapping period" do
      let!(:source_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: source) }
      let!(:destination_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: destination) }

      it "raises and rolls back the whole merge" do
        expect { service.merge! }.to raise_error(ActiveRecord::RecordInvalid)

        expect(source_period.reload.teacher).to eq(source)
        expect(source.reload.anonymised_at).to be_nil
        expect(TeacherIdChange.where(teacher: destination)).to be_empty
      end
    end

    context "when the source and destination are the same teacher" do
      subject(:service) { described_class.new(author:, source:, destination: source) }

      it "raises a MergeError" do
        expect { service.merge! }.to raise_error(described_class::MergeError, /into itself/)
      end
    end

    describe "declaration participant identity via the API serializer" do
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher: source) }
      let!(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, :with_active_lead_provider, ect_at_school_period:, started_on: ect_at_school_period.started_on, finished_on: nil) }
      let!(:declaration) { FactoryBot.create(:declaration, training_period: ect_training_period) }

      it "reports the moved declaration under the destination participant id" do
        service.merge!

        json = JSON.parse(API::DeclarationSerializer.render(declaration.reload))
        expect(json.dig("attributes", "participant_id")).to eq(destination.api_id)
      end
    end
  end
end
