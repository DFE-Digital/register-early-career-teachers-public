module GIAS
  class Reconcile
    class UnreconcilableSchoolError < StandardError; end

    def initialize(urns)
      @gias_schools = GIAS::School.where(urn: urns)
      @unreconcilable_urns = []
    end

    def call
      gias_schools.find_each do |gias_school|
        reconcile(gias_school)
      rescue StandardError => e
        @unreconcilable_urns << gias_school.urn

        Sentry.capture_exception(
          e,
          extra: metadata(gias_school)
        )
      end

      @unreconcilable_urns
    end

  private

    attr_reader :gias_schools

    def reconcile(gias_school)
      return if GIAS::Reconciliation::Replace.replace!(gias_school)
      return if GIAS::Reconciliation::Open.open!(gias_school)
      return if GIAS::Reconciliation::Merge.merge!(gias_school)
      return if GIAS::Reconciliation::Close.close!(gias_school)

      raise UnreconcilableSchoolError, "School with URN #{gias_school.urn} could not be reconciled"
    end

    def metadata(gias_school)
      {
        urn: gias_school.urn,
        status: gias_school.status,
        closed_on: gias_school.closed_on,
        predecessor_urns: gias_school.predecessors&.pluck(:urn),
        successor_urns: gias_school.successors&.pluck(:urn)
      }
    end
  end
end
