def describe_delivery_partner(dp)
  print_seed_info(dp.name, indent: 2)
end

DeliveryPartner.create!(name: 'Rise Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Miller Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Grain Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Artisan Education Group').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Rising Minds Network').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Proving Potential Teaching School Hub').tap { |dp| describe_delivery_partner(dp) }
DeliveryPartner.create!(name: 'Harvest Academy').tap { |dp| describe_delivery_partner(dp) }
