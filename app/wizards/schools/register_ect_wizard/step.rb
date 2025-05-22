module Schools
  module RegisterECTWizard
    class Step < ApplicationWizardStep
      delegate :ect, :school, :valid_step?, to: :wizard

      def self.permitted_params = []

      def next_step = nil

      def save!
        persist if valid_step?
      end

    private

      def fetch_trs_teacher(**args)
        ::TRS::APIClient.build.find_teacher(**args)
      rescue TRS::Errors::TeacherNotFound
        TRS::Teacher.new({})
      end

      def persist = ect.update(step_params)

      def pre_populate_attributes
        self.class.permitted_params.each do |key|
          send("#{key}=", ect.send(key))
        end
      end

      def step_params = wizard.step_params.to_h
    end
  end
end
