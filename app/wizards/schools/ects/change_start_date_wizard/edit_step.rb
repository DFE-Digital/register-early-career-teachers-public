module Schools
  module ECTs
    module ChangeStartDateWizard
      class EditStep < ECTs::Step
        attr_accessor :start_date

        validate :start_date_valid

        def self.permitted_params
          %i[
            start_date
            start_date(1i)
            start_date(2i)
            start_date(3i)
          ]
        end

        def next_step
          return :cannot_use_date unless start_date_contract_period

          if start_date_as_date.past? ||
              start_date_contract_period.enabled?
            :check_answers
          else
            :cannot_use_date
          end
        end

        def save!
          return false unless valid_step?

          store.start_date = start_date_input.date_as_hash
        end

      private

        def pre_populate_attributes
          return unless store.start_date

          self.start_date = Schools::Validation::ECTStartDate
            .new(date_as_hash: store.start_date)
            .date_as_hash
        end

        def start_date_valid
          return if start_date_input.valid?

          errors.add(
            :start_date,
            start_date_input.error_message
          )
        end

        def start_date_input
          @start_date_input ||=
            Schools::Validation::ECTStartDate.new(
              date_as_hash: start_date
            )
        end

        def start_date_as_date
          start_date_input.value_as_date
        end

        def start_date_contract_period
          @start_date_contract_period ||=
            ContractPeriod.containing_date(start_date_as_date)
        end
      end
    end
  end
end
