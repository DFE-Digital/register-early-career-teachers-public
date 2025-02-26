# frozen_string_literal: true

module Schools
  module RegisterECTWizard
    class Step < ApplicationWizardStep
      include ActiveRecord::AttributeAssignment

      delegate :ect, :school, :valid_step?, to: :wizard
      delegate :independent?, to: :school, prefix: true

      def next_step
      end

      def save!
        persist if valid_step?
      end

      def self.permitted_params
        []
      end

    private

      def fetch_trs_teacher(**args)
        ::TRS::APIClient.new.find_teacher(**args)
      rescue TRS::Errors::TeacherNotFound
        TRS::Teacher.new({})
      end

      def persist
        ect.update(step_params)
      end

      def pre_populate_attributes
        self.class.permitted_params.each do |key|
          send("#{key}=", ect.send(key))
        end
      end

      def step_params
        wizard.step_params.to_h
      end
    end
  end
end
