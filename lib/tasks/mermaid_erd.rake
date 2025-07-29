namespace :erd do
  desc 'Generate Mermaid entity relationship diagram'
  task generate: :environment do
    unless Rails.env.development?
      puts '[⚠] Mermaid ERD generation is only allowed in development environment'
      next
    end

    require Rails.root.join('lib/mermaid_erd/generator')

    config_path = Rails.root.join('config/mermaid_erd.yml')
    output_path = Rails.root.join('documentation/domain-model.md')

    MermaidErd::Generator.new(
      config_path:,
      output_path:
    ).generate

    puts "[✔] Mermaid ERD diagram added to: #{output_path.relative_path_from(Rails.root)}"
  end

  namespace :post_migrate do
    desc "Show a reminder to update the Mermaid ER diagram after migrations"
    task reminder: :environment do
      if $stdout.tty?
        cyan = "\e[36m"
        bold = "\e[1m"
        reset = "\e[0m"
      else
        cyan = bold = reset = ""
      end

      puts "\n#{bold}#{cyan}[ℹ] If this migration added or modified database tables, consider:#{reset}"
      puts "    • Updating the Mermaid ER diagram: #{bold}bundle exec rake erd:generate#{reset}"
      puts "    • Excluding models in: #{bold}config/mermaid_erd.yml#{reset}\n\n"
    end
  end
end

if Rails.env.development?
  Rake::Task["db:migrate"].enhance do
    Rake::Task["erd:post_migrate:reminder"].invoke
  end
end
