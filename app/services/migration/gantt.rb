module Migration
  module Gantt
    def to_png
      IO.popen("plantuml -p", "r+") do |pipe|
        pipe.puts(build)
        pipe.close_write
        pipe.read
      end
    end

    def colour(lead_provider)
      {
        "Ambition Institute" => "gold",
        "Best Practice Network" => "deeppink",
        "Capita" => "cyan",
        "Education Development Trust" => "slateblue",
        "National Institute of Teaching" => "cadetblue",
        "Teach First" => "royalblue",
        "UCL Institute of Education" => "lightslategrey"
      }.fetch(lead_provider, "bisque")
    end

    def academic_year_boundaries
      2020.upto(2025).map { |y| %(#{y}/09/01 is colored in salmon) }
    end

    def legend(present_lead_provider_names, extras: {})
      entries = present_lead_provider_names.map do |lead_provider_name|
        %(| <##{colour(lead_provider_name)}> | #{lead_provider_name || 'Expression of interest'} |)
      end

      entries << extras.map { |state, colour| %(| <##{colour}> | #{state} |) }

      <<~LEGEND
        legend
        |= |= Lead provider |
        #{entries.compact.uniq.join("\n")}
        end legend
      LEGEND
    end
  end
end
