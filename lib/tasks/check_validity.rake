namespace :data do
  desc "Scan configured tables and record invalid records into invalid_records"
  task check_validity: :environment do
    totals = CheckValidity.new.call
    $stdout.puts "Total invalid records: #{totals.values.sum}" if totals.any?
  end
end
