# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class Step < DfE::Wizard::Step
      include ActiveRecord::AttributeAssignment

      delegate :ect, :school, :valid_step?, to: :wizard

      def next_step
      end

      def save!
        persist if valid_step?
      end

      def self.permitted_params
        []
      end

    private

      def independent_school?
        GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.include?(school.type_name)
      end

      def fetch_trs_teacher(**args)
        ::TRS::APIClient.new.find_teacher(**args)
      rescue TRS::Errors::TeacherNotFound
        TRS::Teacher.new({})
      end

      def persist
        ect.update(step_params)
      end

      def step_params
        wizard.step_params.to_h
      end
    end
  end
end
