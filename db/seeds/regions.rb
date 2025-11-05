def describe_region(region)
  print_seed_info("#{region.code}: #{region.districts}", indent: 2)
end

FactoryBot.create_list(:region, 13).map do |region|
  describe_region(region)
end
