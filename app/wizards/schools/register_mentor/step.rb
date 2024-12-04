module Schools
  module RegisterMentor
    class Step < DfE::Wizard::Step
      include ActiveRecord::AttributeAssignment

      delegate :mentor, :valid_step?, to: :wizard

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
        mentor.update(step_params)
      end

      def step_params
        wizard.step_params.to_h
      end
    end
  end
end