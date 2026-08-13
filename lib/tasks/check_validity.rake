namespace :data do
  desc "Scan for invalid records"
  task check_validity: :environment do
    CheckValidity.new.call
    InvalidRecord.group(:table_name).count.each do |table_name, count|
      $stdout.puts "#{table_name}: #{count} invalid"
    end
  end
end
