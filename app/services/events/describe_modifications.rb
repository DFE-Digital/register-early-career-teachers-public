module Events
  # Describe the changes made in an ActiveRecord object so they
  # can be recorded in the event log
  #
  # ActiveRecord shows changes in this format:
  # ab = AppropriateBody.assign_attributes(local_authority_code: 419)
  # ab.changes
  # => {"local_authority_code"=>[418, 419]}
  #
  # We want them in a human-readable list:
  #
  # Local authority code changed from 418 to 419
  class DescribeModifications
    attr_reader :modifications

    def initialize(modifications)
      @modifications = modifications
    end

    def describe
      return if modifications.nil?

      modifications.map do |attribute_name, modification|
        TransitionDescription.for(
          attribute_name,
          from: modification[0],
          to: modification[1]
        )
      end
    end

  private

    def format(value)
      formatted_value = case value
                        when Date
                          value.to_formatted_s(:govuk_short)
                        else
                          value
                        end

      %('#{formatted_value}')
    end
  end
end
