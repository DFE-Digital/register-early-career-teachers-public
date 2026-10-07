class DisambiguateCornwallDistricts
  DISTRICTS = {
    "SW8" => ["Cornwall West", "Isles of Scilly"],
    "SW11" => ["Cornwall East"],
  }.freeze

  def call
    ActiveRecord::Base.transaction do
      DISTRICTS.each do |code, districts|
        Region.find_by!(code:).update!(districts:)
      end
    end
  end
end
