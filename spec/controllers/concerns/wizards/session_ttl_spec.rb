RSpec.describe Wizards::SessionTTL, type: :concern do
  include ActiveSupport::Testing::TimeHelpers

  let(:test_class) do
    Class.new do
      include Wizards::SessionTTL
      attr_reader :session

      def initialize = @session = {}
      def session_ttl = 1.hour

      def store
        @store ||= SessionRepository.new(session:, form_key: "test_form")
      end
    end
  end

  let(:instance) { test_class.new }

  describe "#touch_store" do
    it "sets last_touched_at on the store" do
      freeze_time do
        instance.send(:touch_store)
        expect(instance.store.last_touched_at).to eq(Time.zone.now.to_i)
      end
    end
  end

  describe "#expire_store_if_stale" do
    it "resets the store when stale" do
      freeze_time do
        instance.store.last_touched_at = 2.hours.ago.to_i
        instance.send(:expire_store_if_stale)
        expect(instance.session).not_to have_key("test_form")
      end
    end

    it "keeps the store when within TTL" do
      freeze_time do
        instance.store.last_touched_at = 30.minutes.ago.to_i
        instance.send(:expire_store_if_stale)
        expect(instance.session).to have_key("test_form")
      end
    end

    it "does not reset when there is no last_touched_at" do
      instance.send(:expire_store_if_stale)
      expect(instance.session).to have_key("test_form")
    end
  end
end
