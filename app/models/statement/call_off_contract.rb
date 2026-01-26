class Statement::CallOffContract < ApplicationRecord
  belongs_to :statement

  def bands
    klass = Struct.new(:letter, :max, :per_participant, :output_payment_percentage, :service_fee_percentage)

    %i[a b c d].filter_map do |letter|
      next if self[:"band_#{letter}_max"].zero?

      klass.new(
        letter,
        self[:"band_#{letter}_max"],
        self[:"band_#{letter}_per_participant"],
        self[:"band_#{letter}_output_payment_percentage"],
        self[:"band_#{letter}_service_fee_percentage"]
      )
    end
  end
end
