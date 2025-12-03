RSpec.describe EvidenceHeldValidator, type: :model do
  subject { klass.new(declaration_type:, evidence_held:, training_period:) }

  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      validates :evidence_held, evidence_held: true

      attr_accessor :declaration_type, :evidence_held, :training_period

      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end

      def initialize(declaration_type:, evidence_held:, training_period:)
        @declaration_type = declaration_type
        @evidence_held = evidence_held
        @training_period = training_period
      end
    end
  end
  let(:contract_period) { Struct.new(:detailed_evidence_types_enabled).new(detailed_evidence_types_enabled) }
  let(:training_period) { Struct.new(:for_ect?, :contract_period).new(trainee_type == :ect, contract_period) }

  describe "#validate" do
    context "ECT participant" do
      let(:trainee_type) { :ect }

      context "when contract period has simple evidence types" do
        let(:detailed_evidence_types_enabled) { false }

        context "when `declaration_type` is `started`" do
          let(:declaration_type) { "started" }

          context "when `evidence_held` is nil" do
            let(:evidence_held) { nil }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          context "when `evidence_held` is `other`" do
            let(:evidence_held) { "other" }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end
        end

        context "when `declaration_type` is other than started" do
          let(:declaration_type) { "retained-1" }

          context "when `evidence_held` is nil" do
            let(:evidence_held) { nil }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter a '#/evidence_held' value for this participant.")
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          described_class::SIMPLE_EVIDENCE_TYPES.each do |evidence_type|
            context "when `evidence_held` is `#{evidence_type}`" do
              let(:evidence_held) { evidence_type }

              it "does not show validation error" do
                expect(subject).to be_valid
              end
            end
          end
        end
      end

      context "when contract period has detailed evidence types" do
        let(:detailed_evidence_types_enabled) { true }

        context "when `declaration_type` is `started`" do
          let(:declaration_type) { "started" }

          context "when `evidence_held` is nil" do
            let(:evidence_held) { nil }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          context "when `evidence_held` is `other`" do
            let(:evidence_held) { "other" }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end
        end

        context "when `declaration_type` is other than started" do
          let(:declaration_type) { "retained-1" }

          context "when `evidence_held` is not present" do
            let(:evidence_held) { nil }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter a '#/evidence_held' value for this participant.")
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          context "when `evidence_held` is `other`" do
            let(:evidence_held) { "other" }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end
        end
      end
    end

    context "Mentor participant" do
      let(:trainee_type) { :mentor }

      context "when contract period has simple evidence types" do
        let(:detailed_evidence_types_enabled) { false }

        context "when `declaration_type` is `started`" do
          let(:declaration_type) { "started" }

          context "when `evidence_held` is nil" do
            let(:evidence_held) { nil }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          context "when `evidence_held` is `other`" do
            let(:evidence_held) { "other" }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end
        end

        context "when `declaration_type` is other than started" do
          let(:declaration_type) { "retained-1" }

          context "when `evidence_held` is nil" do
            let(:evidence_held) { nil }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter a '#/evidence_held' value for this participant.")
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          described_class::SIMPLE_EVIDENCE_TYPES.each do |evidence_type|
            context "when `evidence_held` is `#{evidence_type}`" do
              let(:evidence_held) { evidence_type }

              it "does not show validation error" do
                expect(subject).to be_valid
              end
            end
          end
        end
      end

      context "when contract period has detailed evidence types" do
        let(:detailed_evidence_types_enabled) { true }

        context "when `declaration_type` is `started`" do
          let(:declaration_type) { "started" }

          context "when `evidence_held` is nil" do
            let(:evidence_held) { nil }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          context "when `evidence_held` is `other`" do
            let(:evidence_held) { "other" }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end
        end

        context "when `declaration_type` is other than started" do
          let(:declaration_type) { "completed" }

          context "when `evidence_held` is not present" do
            let(:evidence_held) { nil }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter a '#/evidence_held' value for this participant.")
            end
          end

          context "when `evidence_held` is invalid" do
            let(:evidence_held) { "one-term-induction" }

            it "has a meaningful error", :aggregate_failures do
              expect(subject).to be_invalid
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:evidence_held, "Enter an available '#/evidence_held' type for this participant.")
            end
          end

          context "when `evidence_held` is `other`" do
            let(:evidence_held) { "75-percent-engagement-met" }

            it "does not show validation error" do
              expect(subject).to be_valid
            end
          end
        end
      end
    end
  end

  describe ".evidence_held_required?" do
    subject { described_class.evidence_held_required?(record) }

    let(:record) { Struct.new(:declaration_type).new(declaration_type) }

    context "when `declaration_type` is nil" do
      let(:declaration_type) { nil }

      it "evidence_held is not required" do
        expect(subject).to be(false)
      end
    end

    context "when `declaration_type` is `started`" do
      let(:declaration_type) { "started" }

      it "evidence_held is not required" do
        expect(subject).to be(false)
      end
    end

    context "when `declaration_type` is other than started" do
      let(:declaration_type) { "retained-1" }

      it "evidence_held is required" do
        expect(subject).to be(true)
      end
    end
  end

  describe ".evidence_held_allowed?" do
    subject { described_class.evidence_held_allowed?(record) }

    let(:record) { Struct.new(:declaration_type, :training_period).new(declaration_type, training_period) }
    let(:training_period) { Struct.new(:contract_period).new(contract_period) }

    context "when contract period has simple evidence types" do
      let(:detailed_evidence_types_enabled) { false }

      context "when `declaration_type` is nil" do
        let(:declaration_type) { nil }

        it "evidence_held is not allowed" do
          expect(subject).to be(false)
        end
      end

      context "when `declaration_type` is `started`" do
        let(:declaration_type) { "started" }

        it "evidence_held is not allowed" do
          expect(subject).to be(false)
        end
      end

      context "when `declaration_type` is other than started" do
        let(:declaration_type) { "retained-1" }

        it "evidence_held is allowed" do
          expect(subject).to be(true)
        end
      end
    end

    context "when contract period has detailed evidence types" do
      let(:detailed_evidence_types_enabled) { true }

      context "when `declaration_type` is nil" do
        let(:declaration_type) { nil }

        it "evidence_held is allowed" do
          expect(subject).to be(true)
        end
      end

      context "when `declaration_type` is `started`" do
        let(:declaration_type) { "started" }

        it "evidence_held is allowed" do
          expect(subject).to be(true)
        end
      end

      context "when `declaration_type` is other than started" do
        let(:declaration_type) { "retained-1" }

        it "evidence_held is allowed" do
          expect(subject).to be(true)
        end
      end
    end
  end
end
