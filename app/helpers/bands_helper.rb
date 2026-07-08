module BandsHelper
  def label_for(band:)
    "Band #{band.letter}"
  end

  def capacity_description_for(band:)
    "#{band.min_declarations} - #{band.max_declarations}"
  end
end
