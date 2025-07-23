# frozen_string_literal: true

RSpec.shared_examples "a declarative touch model" do |when_changing: [], on_event: %i[update], timestamp_attribute: :updated_at, target_optional: true|
  if :update.in?(on_event)
    before { instance } # Ensure its created first.

    when_changing.each do |attribute_to_change|
      context "when the #{attribute_to_change} attribute changes" do
        let(:new_value) do
          column = instance.class.columns_hash[attribute_to_change.to_s]
          if column.type == :enum
            instance.class.defined_enums[attribute_to_change.to_s].keys.excluding(instance[attribute_to_change]).sample
          else
            Faker::Types.send("rb_#{column.type}")
          end
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

        if target_optional
          context "when the target is nil" do
            let(:target) { nil }

            it "does not raise an error" do
              expect { instance.update_attribute(attribute_to_change, new_value) }.not_to raise_error
            end
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

  if :create.in?(on_event)
    it "touches the #{timestamp_attribute} of the associated model(s) on create" do
      expect {
        instance.save!
      }.to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } }.to(all(be_within(5.seconds).of(Time.current))))
    end

    it "does not touch the updated_at of the associated model(s) on create" do
      expect {
        instance.save!
      }.not_to(change { Array.wrap(target).map { |t| t.reload.updated_at } })
    end
  end

  if :destroy.in?(on_event)
    it "touches the #{timestamp_attribute} of the associated model(s) on destroy" do
      expect {
        instance.destroy!
      }.to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } }.to(all(be_within(5.seconds).of(Time.current))))
    end

    it "does not touch the updated_at of the associated model(s) on create" do
      expect {
        instance.destroy!
      }.not_to(change { Array.wrap(target).map { |t| t.reload.updated_at } })
    end
  end
end
