if defined?(Rails::Console) && Rails.env.production?
  puts "\n⚠️  You are opening a Rails console in PRODUCTION."
  print "Type 'production' to continue: "

  input = $stdin.gets.strip
  unless input == "production"
    puts "Aborting console startup."
    exit(1)
  end
end
