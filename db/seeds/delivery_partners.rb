def describe_delivery_partner(delivery_partner)
  print_seed_info(delivery_partner.name, indent: 2)
end

[
  'Rise Teaching School Hub',
  'Miller Teaching School Hub',
  'Grain Teaching School Hub',
  'Artisan Education Group',
  'Rising Minds Network',
  'Proving Potential Teaching School Hub',
  'Harvest Academy'
].each do |name|
  delivery_partner = DeliveryPartner.create!(name:)
  describe_delivery_partner(delivery_partner)
end
