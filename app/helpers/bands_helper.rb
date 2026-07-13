module BandsHelper
  def band_label(band:)
    "Band #{band.letter}"
  end

  def band_capacity_description(band:)
    "#{band.min_declarations} - #{band.max_declarations}"
  end
end
