class AddRectPerformanceGainRatioToParityCheckResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :parity_check_responses, :rect_performance_gain_ratio, :decimal, precision: 6, scale: 1
  end
end
