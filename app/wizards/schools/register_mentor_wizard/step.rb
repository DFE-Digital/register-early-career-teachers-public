module Schools
  module RegisterMentorWizard
    class Step < ApplicationWizardStep
      delegate :ect, :mentor, :valid_step?, :author, to: :wizard

      def self.permitted_params = []

      def next_step = nil

      def save!
        persist if valid_step?
      end

      def fetch_trs_teacher(**args)
        ::TRS::APIClient.build.find_teacher(**args)
      rescue TRS::Errors::TeacherNotFound
        TRS::Teacher.new({})
      end

    private

      def persist = mentor.update(step_params)

      def pre_populate_attributes
        self.class.permitted_params.each do |key|
          send("#{key}=", mentor.send(key))
        end
      end

      def step_params = wizard.step_params.to_h
    end
  end
end
