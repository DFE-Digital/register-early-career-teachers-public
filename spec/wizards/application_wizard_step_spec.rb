RSpec.describe ApplicationWizardStep, type: :model do
  let(:permitted_params) { %i[param1 param2] }
  let(:instance) { described_class.new(params) }

  before do
    described_class.class_exec(permitted_params) { |permitted_params| attr_accessor(*permitted_params) }
    allow(described_class).to receive(:permitted_params).and_return(permitted_params)
  end

  describe "#initialize" do
    context "when permitted params are provided" do
      let(:params) { { param1: 1 } }

      before do
        allow(instance).to receive(:pre_populate_attributes).and_call_original
      end

      it "does not call pre_populate_attributes" do
        expect(instance).not_to have_received(:pre_populate_attributes)
      end
    end

    context "when no permitted params are provided" do
      let(:params) { {} }

      before do
        allow_any_instance_of(described_class).to receive(:pre_populate_attributes).and_return(nil)
      end

      it "calls pre_populate_attributes" do
        expect(instance).to have_received(:pre_populate_attributes)
      end
    end
  end

  describe "#pre_populate_attributes" do
    let(:params) { { param1: 1 } }

    it "raises NotImplementedError" do
      expect { instance.send(:pre_populate_attributes) }.to raise_error(NotImplementedError)
    end
  end

  describe "empty store guard on save!" do
    let(:store) { FactoryBot.build(:session_repository) }
    let(:wizard) { instance_double(ApplicationWizard, store:) }

    # Build a fresh subclass of ApplicationWizardStep so that the inherited
    # hook re-prepends the guard module on it.
    let(:subclass) do
      Class.new(ApplicationWizardStep) do
        attr_accessor :step_name

        def self.permitted_params = []

        def pre_populate_attributes
        end

        def save! = :saved
      end
    end

    let(:step) { subclass.new(wizard:).tap { |s| s.step_name = step_name } }

    context "when the step is a CheckAnswers step and the store is empty" do
      let(:step_name) { "CheckAnswers" }

      it "raises EmptyStoreError instead of calling save!" do
        expect { step.save! }.to raise_error(ApplicationWizardStep::EmptyStoreError)
      end
    end

    context "when the step is a CheckAnswers step and the store has data" do
      let(:step_name) { "CheckAnswers" }

      before { store[:something] = "present" }

      it "calls the underlying save!" do
        expect(step.save!).to eq(:saved)
      end
    end

    context "when the step is not a CheckAnswers step" do
      let(:step_name) { "Edit" }

      it "calls the underlying save! even when the store is empty" do
        expect(step.save!).to eq(:saved)
      end
    end
  end
end
