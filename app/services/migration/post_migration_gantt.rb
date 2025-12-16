module Migration
  class PostMigrationGantt
    include Gantt

    TEMP_LP_NAME = "Ambition Institute"

    attr_reader :ect_at_school_periods, :mentor_at_school_periods

    def initialize(ect_at_school_periods:, mentor_at_school_periods: [])
      @ect_at_school_periods = ect_at_school_periods
      @mentor_at_school_periods = mentor_at_school_periods
    end

    def build
      <<~PLANTUML
        @startgantt

        hide footbox
        printscale monthly
        project starts on #{earliest_start}

        #{academic_year_boundaries.join("\n")}

        #{ect_at_school_period_bars.join("\n")}

        #{legend(present_lead_provider_names, extras: extra_keys)}

        @endgantt
      PLANTUML
    end

    def earliest_start
      [ect_at_school_periods, mentor_at_school_periods].flatten.map(&:started_on).min
    end

    def present_lead_provider_names
      # TODO: get a list of all the lead providers associated with this teacher, either
      #       as an ECT or mentor
      at_school_periods.flat_map(&:training_periods).compact.map { it.lead_provider&.name }
    end

    def extra_keys
      if at_school_periods.flat_map(&:training_periods).compact.any?(&:school_led_training_programme?)
        { "School led" => "yellow" }
      else
        {}
      end
    end

    def at_school_periods
      [*ect_at_school_periods, *mentor_at_school_periods]
    end

    def at_school_periods_grouped_by_school
      at_school_periods.group_by(&:school)
    end

    def ect_at_school_period_bars
      urn = nil

      at_school_periods_grouped_by_school.map do |school, at_school_periods|
        chunk = []

        at_school_periods.each do |at_school_period|
          chunk << %(-- #{school.urn} --) if school.urn != urn

          identifier = case at_school_period
                       when MentorAtSchoolPeriod
                         %(Mentor:#{at_school_period.id})
                       when ECTAtSchoolPeriod
                         %(ECT:#{at_school_period.id})
                       end

          chunk << %([#{identifier}] starts on #{at_school_period.started_on} and ends on #{at_school_period.finished_on || Time.zone.today})

          at_school_period.mentorship_periods.each do |mp|
            mp_identifier = "Mentored by #{mp.mentor.teacher.trn}"

            chunk << <<~BAR
              [#{mp_identifier}] starts on #{mp.started_on} and ends on #{mp.finished_on || Time.zone.today}
              [#{mp_identifier}] is colored in red
            BAR
          end

          at_school_period.training_periods.each do |tp|
            tp_identifier = %(Training period:#{tp.id})

            chunk << %([#{tp_identifier}] starts on #{tp.started_on} and ends on #{tp.finished_on || Time.zone.today})

            case tp.training_programme
            when "provider_led"
              chunk << if (lead_provider = tp.lead_provider)
                         %([#{tp_identifier}] is colored in #{colour(lead_provider.name)})
                       else
                         %([#{tp_identifier}] is colored in bisque)
                       end
            when "school_led"
              chunk << %([#{tp_identifier}] starts on #{tp.started_on} and ends on #{tp.finished_on || Time.zone.today})
              chunk << %([#{tp_identifier}] is colored in yellow)
            end
          end

          urn = school.urn
        end

        chunk.join("\n")
      end
    end
  end
end
