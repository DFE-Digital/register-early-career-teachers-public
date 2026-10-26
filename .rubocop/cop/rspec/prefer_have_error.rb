module RuboCop
  module Cop
    module RSpec
      # Checks for expectations made directly against `errors[:attribute]`
      # and suggests the `have_error` / `have_no_error` matchers instead.
      #
      # `have_error` runs validations itself, so an expectation is only
      # flagged when the errors visibly come from a validation call on the same
      # record, either in the example or in an enclosing `before` hook.
      # Errors added by callbacks, `save!`, `destroy!` or services are left
      # alone, as are matchers that assert more than the presence of one
      # message (`eq`, `contain_exactly`, `match_array`, `include` with several
      # messages).
      #
      # @example
      #   # bad
      #   form.valid?(:verify)
      #   expect(form.errors[:code]).to include("Enter the code")
      #
      #   step.valid?
      #   expect(step.errors[:email]).to be_empty
      #
      #   # good
      #   expect(form).to have_error(:code, "Enter the code", :verify)
      #   expect(step).to have_no_error(:email)
      class PreferHaveError < Base
        extend AutoCorrector

        MSG = "Use `have_error` or `have_no_error` instead of asserting on `errors`."

        # @!method errors_expectation(node)
        def_node_matcher :errors_expectation, <<~PATTERN
          (send
            (send nil? :expect
              (send {(send $!nil? :errors) (send (send $!nil? :errors) :messages)} :[] $sym))
            ${:to :not_to :to_not}
            ${(send nil? :include !splat) (send nil? {:be_present :be_empty :be_blank})})
        PATTERN

        # @!method validation_contexts(node, record)
        def_node_search :validation_contexts, <<~PATTERN
          {
            (send %1 {:valid? :invalid? :validate} $...)
            (send (send nil? :expect %1) _ (send nil? {:be_valid :be_invalid} $...))
          }
        PATTERN

        def on_send(node)
          errors_expectation(node) do |record, attribute, runner, matcher|
            context = validation_context(node, record)
            next unless context

            add_offense(node) do |corrector|
              corrector.replace(node, "expect(#{record.source}).to #{replacement_matcher(attribute, runner, matcher, context)}")
            end
          end
        end

      private

        def replacement_matcher(attribute, runner, matcher, context)
          expects_error = matcher.method?(:include) || matcher.method?(:be_present)
          arguments = [attribute, matcher.first_argument, *context].map { it&.source || "nil" }
          arguments.pop while arguments.last == "nil"

          "#{expects_error == (runner == :to) ? 'have_error' : 'have_no_error'}(#{arguments.join(', ')})"
        end

        def validation_context(node, record)
          example = node.each_ancestor(:block).find { example?(it) }
          return if example.nil?

          before_hooks = example.each_ancestor(:block).flat_map do |group|
            RuboCop::RSpec::ExampleGroup.new(group).hooks.select { |hook| hook.name == :before }.map(&:to_node).reverse
          end

          [example, *before_hooks].each do |scope|
            context = validation_contexts(scope, record).to_a.last
            return context if context
          end

          nil
        end
      end
    end
  end
end
