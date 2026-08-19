module GIAS
  class Reconcile
    def initialize(urns)
      @urns_to_reconcile = urns.dup
    end

    def call
      replace!
      merge!
      open!
      close!

      log_failures

      urns_to_reconcile
    end

  private

    attr_accessor :urns_to_reconcile

    def replace!
      gias_schools_to_reconcile.find_each do |gias_school|
        capture_error(gias_school) do
          if GIAS::Reconciliation::Replace.replace!(gias_school)
            urns_to_reconcile.delete(gias_school.urn)
            urns_to_reconcile.delete(gias_school.successor.urn)
          end
        end
      end
    end

    def merge!
      gias_schools_to_reconcile.find_each do |gias_school|
        capture_error(gias_school) do
          if GIAS::Reconciliation::Merge.merge!(gias_school)
            urns_to_reconcile.delete(gias_school.urn)
            urns_to_reconcile.delete(gias_school.successor.urn)
          end
        end
      end
    end

    def open!
      gias_schools_to_reconcile.find_each do |gias_school|
        capture_error(gias_school) do
          if GIAS::Reconciliation::Open.open!(gias_school)
            urns_to_reconcile.delete(gias_school.urn)
          end
        end
      end
    end

    def close!
      gias_schools_to_reconcile.find_each do |gias_school|
        capture_error(gias_school) do
          if GIAS::Reconciliation::Close.close!(gias_school)
            urns_to_reconcile.delete(gias_school.urn)
          end
        end
      end
    end

    def capture_error(gias_school)
      yield
    rescue StandardError => e
      Sentry.capture_exception(e, extra: metadata(gias_school))
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

    def log_failures
      gias_schools_to_reconcile.find_each do |gias_school|
        Sentry.capture_message("Could not reconcile school with URN #{gias_school.urn}", level: :info, extra: metadata(gias_school))
      end
    end

    def gias_schools_to_reconcile
      GIAS::School.where(urn: urns_to_reconcile)
    end
  end
end
