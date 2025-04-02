# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `require 'rails_helper'` in spec files.
      # Rails helper should be required in spec_helper.rb, not in individual spec files.
      #
      # @example
      #   # bad
      #   require 'rails_helper'
      #
      #   RSpec.describe MyClass do
      #     # ...
      #   end
      #
      #   # good
      #   RSpec.describe MyClass do
      #     # ...
      #   end
      class RequireRailsHelper < RuboCop::Cop::Base
        MSG = "Do not require 'rails_helper' in individual spec files. It is already required in spec_helper.rb."

        def on_send(node)
          return unless require_rails_helper?(node)

          add_offense(node)
        end

      private

        def require_rails_helper?(node)
          node.command?(:require) && node.first_argument.str_content == 'rails_helper'
        end
      end
    end
  end
end
