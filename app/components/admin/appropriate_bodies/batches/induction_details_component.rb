module Admin
  module AppropriateBodies
    module Batches
      class InductionDetailsComponent < ApplicationComponent
        attr_reader :batch

        def initialize(batch:)
          @batch = batch
        end

        # @return [Boolean]
        def render?
          batch.recorded_count.positive?
        end

      private

        delegate :id, :claim?, :action?, to: :batch
        delegate :training_programme_name, :teacher_full_name, to: :helpers

        # @return [String]
        def caption
          case
          when claim? then "Opened induction periods (#{rows.count})"
          when action? then "Closed induction periods (#{rows.count})"
          else
            raise StandardError, "Unknown #{batch.class}#batch_type for #{id}"
          end
        end

        # @return [Array<String>]
        def head
          case
          when claim? then ['TRN', 'Name', 'Induction period start date', 'Induction programme']
          when action? then ['TRN', 'Name', 'Induction period end date', 'Number of terms', 'Outcome']
          else
            raise StandardError, "Unknown #{batch.class}#batch_type for #{id}"
          end
        end

        # @return [Array<Array<String>>]
        def rows
          inductions.map { |induction_period| induction_period_row(induction_period) }
        end

        # @param induction_period [InductionPeriod]
        # @return [String]
        def induction_outcome_tag(induction_period)
          colours = { release: 'yellow', pass: 'green', fail: 'red' }
          outcome = induction_period.outcome || 'release'
          govuk_tag(text: outcome.titleize, colour: colours[outcome.to_sym])
        end

        # @param induction_period [InductionPeriod]
        # @return [Array<String>]
        def induction_period_row(induction_period)
          [
            induction_period.teacher.trn,
            link_to_teacher(induction_period.teacher),
            (induction_period.finished_on.to_fs(:govuk) if action?),
            (induction_period.number_of_terms.to_s if action?),
            (induction_outcome_tag(induction_period) if action?),
            (induction_period.started_on.to_fs(:govuk) if claim?),
            (training_programme_name(induction_period.training_programme) if claim?)
          ].compact
        end

        # @param teacher [Teacher]
        # @return [String]
        def link_to_teacher(teacher)
          govuk_link_to(teacher_full_name(teacher), admin_teacher_path(teacher))
        end

        # @return [InductionPeriod::ActiveRecord_Relation]
        def inductions
          InductionPeriod
              .includes(:teacher, :events)
              .where(events: { pending_induction_submission_batch_id: id })
              .order(:trs_last_name)
        end
      end
    end
  end
end
