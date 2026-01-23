module Migration
  class PreMigrationGantt
    include Gantt

    attr_reader :id, :induction_records, :declarations

    def initialize(induction_records, declarations)
      @induction_records = induction_records
      @declarations = declarations
    end

    def build
      <<~PLANTUML
        @startgantt

        hide footbox
        printscale monthly
        project starts on #{earliest_start}

        #{academic_year_boundaries.join("\n")}
        #{induction_record_descriptions.join("\n")}
        #{declaration_descriptions.join("\n")}
        #{legend(present_lead_provider_names)}

        @endgantt
      PLANTUML
    end

  private

    def earliest_start
      induction_records.first.start_date.to_s
    end

    def induction_record_descriptions
      induction_records.group_by(&:urn).flat_map do |urn, records|
        chunk = [%(-- #{urn} --)]

        records.sort_by(&:start_date).each do |ir|
          identifier = ir.induction_record_id[0..7]

          chunk << <<~LINE
            [#{identifier}] starts on #{ir.start_date} and ends on #{ir.end_date || Time.zone.today}
            [#{identifier}] is colored in #{colour(ir.lead_provider_name)}
          LINE

          chunk << withdrawn_note(identifier) if ir.withdrawn?
        end

        chunk.join("\n")
      end
    end

    def academic_year_boundaries
      2020.upto(2025).map { |y| %(#{y}/09/01 is colored in salmon) }
    end

    def present_lead_provider_names
      induction_records.map(&:lead_provider_name).uniq
    end

    def withdrawn_note(identifier)
      <<~NOTE
        note bottom
          note for #{identifier}
          withdrawn: true
        end note
      NOTE
    end

    def declaration_descriptions
      declarations.map { |d| %([#{d.declaration_type}] happens at #{d.declaration_date.to_date}) }
    end
  end
end
