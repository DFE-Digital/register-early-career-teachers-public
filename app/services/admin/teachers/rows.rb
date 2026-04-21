module Admin
  module Teachers
    class Rows
      CONTRACT_PERIOD_NOT_APPLICABLE = "not_available"
      NO_ROLE_ASSIGNED = "no_role_assigned"

      ROLE_NAMES = {
        "ect" => "Early career teacher",
        "mentor" => "Mentor",
      }.freeze

      ROLE_SORT_ORDER = ROLE_NAMES.keys.append(NO_ROLE_ASSIGNED).each_with_index.to_h.freeze

      Row = Data.define(:teacher, :role, :contract_period) do
        delegate :id, to: :teacher, prefix: true
        delegate :trn, to: :teacher

        def name
          ::Teachers::Name.new(teacher).full_name
        end

        def role_name
          return "No role assigned" if role == Rows::NO_ROLE_ASSIGNED

          Rows::ROLE_NAMES.fetch(role)
        end

        def contract_period_name
          return if contract_period.blank?
          return "Not applicable" if contract_period == Rows::CONTRACT_PERIOD_NOT_APPLICABLE

          contract_period
        end

        def sort_key
          [
            name.to_s.downcase,
            Rows::ROLE_SORT_ORDER.fetch(role),
            teacher.id
          ]
        end
      end

      def initialize(role: nil, contract_period: nil)
        @role = role.to_s.presence
        @contract_period = contract_period.to_s.presence
      end

      def rows(teachers)
        rows = teachers.flat_map { |teacher| rows_for_teacher(teacher) }
        rows = filter_by_role(rows)
        rows = filter_by_contract_period(rows)

        sort_rows(rows)
      end

    private

      attr_reader :role, :contract_period

      def rows_for_teacher(teacher)
        # Rows are role based, so a single teacher can produce multiple rows
        # (e.g. one for ECT and one for mentor).

        rows = []
        rows << build_row(teacher:, role: "ect", role_period: role_period_for(teacher, "ect")) if ect?(teacher)
        rows << build_row(teacher:, role: "mentor", role_period: role_period_for(teacher, "mentor")) if mentor?(teacher)
        rows << build_row(teacher:, role: NO_ROLE_ASSIGNED) if rows.none?
        rows
      end

      def ect?(teacher)
        teacher.latest_ect_at_school_period.present? ||
          teacher.induction_periods.any?
      end

      def mentor?(teacher)
        teacher.latest_mentor_at_school_period.present?
      end

      def role_period_for(teacher, role)
        teacher.public_send("latest_#{role}_at_school_period")
      end

      def build_row(teacher:, role:, role_period: nil)
        Row.new(
          teacher:,
          role:,
          contract_period: contract_period_for(role_period)
        )
      end

      def contract_period_for(role_period)
        training_period = training_period_for(role_period)
        return if training_period.blank?
        return CONTRACT_PERIOD_NOT_APPLICABLE if training_period.for_ect? && training_period.school_led_training_programme?

        training_period.schedule&.contract_period_year&.to_s
      end

      def training_period_for(role_period)
        role_period&.latest_training_period
      end

      def filter_by_role(rows)
        return rows if role.blank?

        rows.select { |row| row.role == role }
      end

      def filter_by_contract_period(rows)
        return rows if contract_period.blank?

        rows.select { |row| row.contract_period == contract_period }
      end

      def sort_rows(rows)
        rows.sort_by(&:sort_key)
      end
    end
  end
end
