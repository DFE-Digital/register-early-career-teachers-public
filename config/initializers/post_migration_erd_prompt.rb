if Rails.env.development?
  Rake::Task["db:migrate"].enhance do
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
