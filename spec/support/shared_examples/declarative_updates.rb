def generate_new_value(attribute_to_change:)
  column = instance.class.columns_hash[attribute_to_change.to_s]
  if column.type == :enum
    instance.class.defined_enums[attribute_to_change.to_s].keys.excluding(instance[attribute_to_change]).sample
  elsif column.type == :boolean
    !instance[attribute_to_change]
  elsif attribute_to_change.match?("email")
    Faker::Internet.email
  elsif attribute_to_change == :started_on
    (instance[attribute_to_change] || Date.current) + 1.day
  elsif attribute_to_change == :finished_on
    (instance[attribute_to_change] || Date.current) - 1.day
  elsif attribute_to_change.to_s.end_with?("_id")
    association_name = attribute_to_change.to_s.delete_suffix("_id").to_sym
    klass = instance.class.reflect_on_association(association_name).klass
    ActiveRecord::Base.connection.select_value("SELECT last_value FROM #{klass.sequence_name}") + 1
  else
    Faker::Types.send("rb_#{column.type}")
  end
end

RSpec.shared_examples "a declarative touch model", :with_touches do |when_changing: [], on_event: %i[update], timestamp_attribute: :updated_at, target_optional: true|
  if :update.in?(on_event)
    context "when updating" do
      before { instance } # Ensure it's created first.

      when_changing.each do |attribute_to_change|
        context "when the #{attribute_to_change} attribute changes" do
          let(:new_value) { generate_new_value(attribute_to_change:) }

          before { DeclarativeUpdates.skip(:metadata) { will_change_attribute(attribute_to_change:, new_value:) if defined?(will_change_attribute) } }

          it "touches the #{timestamp_attribute} of the associated model(s)" do
            expect {
              instance.update_attribute(attribute_to_change, new_value)
            }.to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } }.to(all(be_within(5.seconds).of(Time.current))))
          end

          context "when wrapped in a skip(:touch) block" do
            around { |example| DeclarativeUpdates.skip(:touch) { example.run } }

            it "does not touch the #{timestamp_attribute} of the associated model(s)" do
              expect {
                instance.update_attribute(attribute_to_change, new_value)
              }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
            end
          end

          context "when wrapped in a generic skip block" do
            around { |example| DeclarativeUpdates.skip { example.run } }

            it "does not touch the #{timestamp_attribute} of the associated model(s)" do
              expect {
                instance.update_attribute(attribute_to_change, new_value)
              }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
            end
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

      if when_changing.empty?
        it "touches the #{timestamp_attribute} of the associated model(s) when an attribute changes" do
          expect {
            instance.update!(updated_at: 1.week.ago)
          }.to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } }.to(all(be_within(5.seconds).of(Time.current))))
        end

        context "when wrapped in a skip(:touch) block" do
          around { |example| DeclarativeUpdates.skip(:touch) { example.run } }

          it "does not touch the #{timestamp_attribute} of the associated model(s)" do
            expect {
              instance.update!(updated_at: 1.week.ago)
            }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
          end
        end

        context "when wrapped in a generic skip block" do
          around { |example| DeclarativeUpdates.skip { example.run } }

          it "does not touch the #{timestamp_attribute} of the associated model(s)" do
            expect {
              instance.update!(updated_at: 1.week.ago)
            }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
          end
        end
      end
    end
  end

  if :create.in?(on_event)
    context "when creating" do
      it "touches the #{timestamp_attribute} of the associated model(s) on create" do
        expect {
          instance
        }.to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } }.to(all(be_within(5.seconds).of(Time.current))))
      end

      it "does not touch the updated_at of the associated model(s) on create" do
        expect {
          instance
        }.not_to(change { Array.wrap(target).map { |t| t.reload.updated_at } })
      end

      context "when wrapped in a skip(:touch) block" do
        around { |example| DeclarativeUpdates.skip(:touch) { example.run } }

        it "does not touch the #{timestamp_attribute} of the associated model(s)" do
          expect { instance }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
        end
      end

      context "when wrapped in a generic skip block" do
        around { |example| DeclarativeUpdates.skip { example.run } }

        it "does not touch the #{timestamp_attribute} of the associated model(s)" do
          expect { instance }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
        end
      end
    end
  end

  if :destroy.in?(on_event)
    context "when destroying" do
      before { instance } # Ensure it's created first.

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

      context "when wrapped in a skip(:touch) block" do
        around { |example| DeclarativeUpdates.skip(:touch) { example.run } }

        it "does not touch the #{timestamp_attribute} of the associated model(s)" do
          expect { instance.destroy! }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
        end
      end

      context "when wrapped in a generic skip block" do
        around { |example| DeclarativeUpdates.skip { example.run } }

        it "does not touch the #{timestamp_attribute} of the associated model(s)" do
          expect { instance.destroy! }.not_to(change { Array.wrap(target).map { |t| t.reload.send(timestamp_attribute) } })
        end
      end
    end
  end
end

RSpec.shared_examples "a declarative metadata model", :with_metadata do |when_changing: [], on_event: %i[update], target_optional: true|
  let(:manager) { instance_double(Metadata::Manager, refresh_metadata!: nil) }

  if :update.in?(on_event)
    context "when updating" do
      before do
        # Ensure it's created first.
        instance
        allow(Metadata::Manager).to receive(:new).and_return(manager)
      end

      when_changing.each do |attribute_to_change|
        context "when the #{attribute_to_change} attribute changes" do
          let(:new_value) { generate_new_value(attribute_to_change:) }

          before { DeclarativeUpdates.skip(:metadata) { will_change_attribute(attribute_to_change:, new_value:) if defined?(will_change_attribute) } }

          it "refreshes the metadata of the associated model(s)" do
            instance.update!(attribute_to_change => new_value)

            expect(manager).to have_received(:refresh_metadata!).with(target)
          end

          context "when wrapped in a skip(:metadata) block" do
            around { |example| DeclarativeUpdates.skip(:metadata) { example.run } }

            it "does not refresh the metadata of the associated model(s)" do
              instance.update!(attribute_to_change => new_value)

              expect(manager).not_to have_received(:refresh_metadata!).with(target)
            end
          end

          context "when wrapped in a generic skip block" do
            around { |example| DeclarativeUpdates.skip { example.run } }

            it "does not refresh the metadata of the associated model(s)" do
              instance.update!(attribute_to_change => new_value)

              expect(manager).not_to have_received(:refresh_metadata!).with(target)
            end
          end

          if target_optional
            context "when the target is nil" do
              let(:target) { nil }

              it "does not raise an error" do
                expect { instance.update(attribute_to_change => new_value) }.not_to raise_error
              end
            end
          end
        end

        it "does not refresh the metadata of the associated model(s) when the #{attribute_to_change} attribute has not changed" do
          existing_value = instance.send(attribute_to_change)
          instance.update!(attribute_to_change => existing_value)

          expect(manager).not_to have_received(:refresh_metadata!).with(target)
        end
      end

      if when_changing.empty?
        it "refreshes the metadata of the associated model(s) when an attribute changes" do
          allow(Metadata::Manager).to receive(:new).and_return(manager)

          instance.update!(updated_at: 1.week.ago)

          expect(manager).to have_received(:refresh_metadata!).with(target)
        end

        context "when wrapped in a skip(:metadata) block" do
          around { |example| DeclarativeUpdates.skip(:metadata) { example.run } }

          it "does not refresh the metadata of the associated model(s)" do
            instance.update!(updated_at: 1.week.ago)

            expect(manager).not_to have_received(:refresh_metadata!).with(target)
          end
        end

        context "when wrapped in a generic skip block" do
          around { |example| DeclarativeUpdates.skip { example.run } }

          it "does not refresh the metadata of the associated model(s)" do
            instance.update!(updated_at: 1.week.ago)

            expect(manager).not_to have_received(:refresh_metadata!).with(target)
          end
        end
      end
    end
  end

  if :create.in?(on_event)
    context "when creating" do
      it "refreshes the metadata of the associated model(s) on create" do
        allow(Metadata::Manager).to receive(:new).and_return(manager)

        instance

        expect(manager).to have_received(:refresh_metadata!).with(target).at_least(:once)
      end
    end

    context "when wrapped in a skip(:metadata) block" do
      around { |example| DeclarativeUpdates.skip(:metadata) { example.run } }

      it "does not refresh the metadata of the associated model(s)" do
        allow(Metadata::Manager).to receive(:new).and_return(manager)

        instance

        expect(manager).not_to have_received(:refresh_metadata!).with(target)
      end
    end

    context "when wrapped in a generic skip block" do
      around { |example| DeclarativeUpdates.skip { example.run } }

      it "does not refresh the metadata of the associated model(s)" do
        allow(Metadata::Manager).to receive(:new).and_return(manager)

        instance

        expect(manager).not_to have_received(:refresh_metadata!).with(target)
      end
    end
  end

  if :destroy.in?(on_event)
    describe "destroy event" do
      before do
        # Ensure it's created first.
        instance

        allow(Metadata::Manager).to receive(:new).and_return(manager)
      end

      context "when destroying" do
        it "refreshes the metadata of the associated model(s) on destroy" do
          instance.destroy!

          expect(manager).to have_received(:refresh_metadata!).with(target)
        end
      end

      context "when wrapped in a skip(:metadata) block" do
        around { |example| DeclarativeUpdates.skip(:metadata) { example.run } }

        it "does not refresh the metadata of the associated model(s)" do
          instance.destroy!

          expect(manager).not_to have_received(:refresh_metadata!).with(target)
        end
      end

      context "when wrapped in a generic skip block" do
        around { |example| DeclarativeUpdates.skip { example.run } }

        it "does not refresh the metadata of the associated model(s)" do
          instance.destroy!

          expect(manager).not_to have_received(:refresh_metadata!).with(target)
        end
      end
    end
  end
end
