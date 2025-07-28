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
end
