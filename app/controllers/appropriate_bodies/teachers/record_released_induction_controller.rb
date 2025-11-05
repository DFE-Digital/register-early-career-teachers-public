module AppropriateBodies
  module Teachers
    class RecordReleasedInductionController < CloseInductionController
      def new
        @record_release = record_release

        super
      end

      def create
        if @teacher.ongoing_induction_period.present?
          @record_release = record_release

          if @record_release.call(induction_params)
            redirect_to ab_teacher_release_ect_path(@teacher)
          else
            render :new, status: :unprocessable_content
          end

        else
          redirect_to ab_teacher_path(@teacher)
        end
      rescue ActiveRecord::RecordInvalid,
             ActiveModel::ValidationError
        render :new, status: :unprocessable_content
      end

    private

      def find_current_teacher
        @teacher = ects.current.find_by!(id: params[:teacher_id])
      end

      def find_former_teacher
        @teacher = ects.former.find_by!(id: params[:teacher_id])
      end

      def record_release
        RecordRelease.new(
          teacher: @teacher,
          appropriate_body_period: @appropriate_body,
          author: current_user
        )
      end

      def induction_params
        params.expect(RecordRelease.induction_params)
      end
    end
  end
end
