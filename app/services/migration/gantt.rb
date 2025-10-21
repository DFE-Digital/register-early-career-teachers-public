module Migration
  class Gantt
    attr_reader :id, :induction_records

    def initialize(induction_records)
      @induction_records = induction_records
    end

    def build
      <<~PLANTUML
        @startgantt

        hide footbox
        printscale monthly
        project starts on #{earliest_start}

        #{academic_year_boundaries.join("\n")}
        #{induction_record_descriptions.join("\n")}
        #{legend}

        @endgantt
      PLANTUML
    end

    def to_png
      IO.popen('plantuml -p', 'r+') do |pipe|
        pipe.puts(build)
        pipe.close_write

        pipe.read
      end
    end

  private

    def earliest_start
      induction_records.first.start_date.to_s
    end

    def induction_record_descriptions
      urn = nil

      induction_records.map do |ir|
        chunk = []

        chunk << %(-- #{ir.urn} --) if ir.urn != urn

        identifier = ir.induction_record_id[0..7]

        chunk << <<~LINE
          [#{identifier}] starts on #{ir.start_date} and ends on #{ir.end_date || Time.zone.today}
          [#{identifier}] is colored in #{colour(ir.lead_provider_name)}
        LINE

        chunk << withdrawn_note(identifier) if ir.withdrawn?

        urn = ir.urn

        chunk.join("\n")
      end
    end

    def academic_year_boundaries
      2020.upto(2025).map { |y| %(#{y}/09/01 is colored in salmon) }
    end

    def colour(lead_provider)
      {
        'Ambition Institute' => 'gold',
        'Best Practice Network' => 'deeppink',
        'Capita' => 'cyan',
        'Education Development Trust' => 'slateblue',
        'National Institute of Teaching' => 'cadetblue',
        'Teach First' => 'royalblue',
        'UCL Institute of Education' => 'lightslategrey'
      }.fetch(lead_provider, 'bisque')
    end

    def withdrawn_note(identifier)
      <<~NOTE
        note bottom
          note for #{identifier}
          withdrawn: true
        end note
      NOTE
    end

    def legend
      entries = induction_records.map(&:lead_provider_name).uniq.map do |lead_provider_name|
        %(| <##{colour(lead_provider_name)}> | #{lead_provider_name} |)
      end

      <<~LEGEND
        legend
        |= |= Lead provider |
        #{entries.join("\n")}
        end legend
      LEGEND
    end

    def declaration_descriptions
      ect_declaration_dates.compact.map { |name, date| %([#{name}] happens at #{date}) }
    end
  end
end
