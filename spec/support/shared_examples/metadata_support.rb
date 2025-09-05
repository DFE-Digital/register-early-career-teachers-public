module OtherNamespace
  class TestUpdater
    def self.perform(model)
      model.update!(id: 0)
    end
  end
end

module Metadata
  class TestUpdater
    def self.perform(model)
      model.update!(id: 0)
    end
  end
end

RSpec.shared_examples "restricts updates to the Metadata namespace" do |factory|
  it "allows updates from within the Metadata namespace" do
    model = FactoryBot.create(factory)
    expect { Metadata::TestUpdater.perform(model) }.not_to raise_error
  end

  it "raises an error when updates are made from outside the Metadata namespace" do
    model = FactoryBot.create(factory)
    expected_message = "Updates to #{described_class} are only allowed from the Metadata namespace"
    expect { OtherNamespace::TestUpdater.perform(model) }.to raise_error(Metadata::Base::UpdateRestrictedError, expected_message)
  end

  it "does not raise an error when bypassing update restrictions" do
    model = FactoryBot.create(factory)
    expect { model.class.bypass_update_restrictions { OtherNamespace::TestUpdater.perform(model) } }.not_to raise_error
  end
end

RSpec.shared_examples "supports refreshing all metadata" do |factory, object_type|
  describe ".refresh_all_metadata!" do
    subject(:refresh_all_metadata) { described_class.refresh_all_metadata!(async:) }

    let(:async) { true }
    let(:object_ids) { [object.id] + FactoryBot.create_list(factory, 2).map(&:id) }

    before { stub_const("Metadata::Handlers::Base::BATCH_SIZE", 2) }

    it "enqueues jobs to refresh metadata for all #{factory} in batches" do
      expect(RefreshMetadataJob).to receive(:perform_later).with(
        object_type:,
        object_ids: object_ids[0..1],
        track_changes: false
      )

      expect(RefreshMetadataJob).to receive(:perform_later).with(
        object_type:,
        object_ids: object_ids[2..2],
        track_changes: false
      )

      refresh_all_metadata
    end

    context "when async is false" do
      let(:async) { false }

      it "enqueues jobs to refresh metadata for all #{factory} in batches" do
        expect(RefreshMetadataJob).to receive(:perform_now).with(
          object_type:,
          object_ids: object_ids[0..1],
          track_changes: false
        )

        expect(RefreshMetadataJob).to receive(:perform_now).with(
          object_type:,
          object_ids: object_ids[2..2],
          track_changes: false
        )

        refresh_all_metadata
      end
    end
  end
end

RSpec.shared_examples "supports tracking metadata upsert changes" do |metadata_model|
  describe "track upsert changes" do
    context "when track_changes is false" do
      it "does not track changes" do
        perform_refresh_metadata

        expect(handler.upsert_changes).to be_empty
      end
    end

    context "when track_changes is true" do
      before { handler.track_changes! }

      it "tracks changes" do
        allow(Sentry).to receive(:capture_message)
        allow(Rails.logger).to receive(:warn)

        perform_refresh_metadata

        expect(handler.upsert_changes).to include(a_hash_including(class: metadata_model.name, id: anything, attributes: anything))
        expect(Sentry).to have_received(:capture_message).with("[Metadata] #{metadata_model.name} change")
        expect(Rails.logger).to have_received(:warn).with(a_string_starting_with("[Metadata] #{metadata_model.name} change:"))
      end
    end
  end
end
