module BandsHelper
  def label_for(band:)
    Admin::Finance::Bands.new(active_lead_provider: band.active_lead_provider).label_for(band:)
  end

  def capacity_description_for(band:)
    Admin::Finance::Bands.new(active_lead_provider: band.active_lead_provider).capacity_description_for(band:)
  end

  def editable?(band:)
    Admin::Finance::Bands.new(active_lead_provider: band.active_lead_provider).editable?(band:)
  end

  def deletable?(band:)
    Admin::Finance::Bands.new(active_lead_provider: band.active_lead_provider).deletable_band?(band:)
  end

  def bands_can_be_added?(active_lead_provider:)
    Admin::Finance::Bands.new(active_lead_provider:).bands_can_be_added?
  end

  def bands_can_be_deleted?(active_lead_provider:)
    Admin::Finance::Bands.new(active_lead_provider:).bands_can_be_deleted?
  end
end
