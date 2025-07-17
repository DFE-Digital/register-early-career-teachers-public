# frozen_string_literal: true

RSpec.shared_examples "a declarative touch model" do |when_changing:, timestamp_attribute:|
  when_changing.each do |attribute_to_change|
    context "when the #{attribute_to_change} attribute changes" do
      let(:new_value) do
        column = instance.class.columns_hash[attribute_to_change.to_s]
        Faker::Types.send("rb_#{column.type}")
      end

      before do
        will_change_attribute(attribute_to_change:, new_value:) if defined?(will_change_attribute)
      end

      it "touches the #{timestamp_attribute} of the associated model(s)" do
        expect {
          instance.update_attribute(attribute_to_change, new_value)
        }.to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } }.to(all(be_within(5.seconds).of(Time.current))))
      end

      it "does not touch the updated_at of the associated model(s)" do
        # If the target is the same as the instance the updated_at will always be updated.
        unless instance == target
          expect {
            instance.update_attribute(attribute_to_change, new_value)
          }.not_to(change { Array.wrap(target).map { |t| t.reload.updated_at } })
        end
      end

      context "when the target is nil" do
        let(:target) { nil }

        it "does not raise an error" do
          expect { instance.update_attribute(attribute_to_change, new_value) }.not_to raise_error
        end
      end
    end

    it "does not touch the associated model(s) when the #{attribute_to_change} attribute has not changed" do
      existing_value = instance.send(attribute_to_change)
      expect {
        instance.update!(attribute_to_change => existing_value)
      }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
    end
  end
end
