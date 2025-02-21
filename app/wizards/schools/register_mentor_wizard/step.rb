module Schools
  module RegisterMentorWizard
    class Step < ApplicationWizardStep
      include ActiveRecord::AttributeAssignment

      delegate :current_user, :ect, :mentor, :valid_step?, to: :wizard

      def self.permitted_params = []

      def next_step = nil

      def save!
        persist if valid_step?
      end

    private

      def fetch_trs_teacher(**args)
        ::TRS::APIClient.new.find_teacher(**args)
      rescue TRS::Errors::TeacherNotFound
        TRS::Teacher.new({})
      end

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
