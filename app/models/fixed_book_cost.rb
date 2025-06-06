# == Schema Information
#
# Table name: fixed_book_costs
#
#  id          :integer          not null, primary key
#  amount      :decimal(10, 2)   not null
#  created_on  :date             not null
#  description :string(255)      not null
#  file_ref    :string(255)
#  sku_id      :integer          not null
#
# Indexes
#
#  fk_fixed_book_costs_sku_id  (sku_id)
#
# Foreign Keys
#
#  fk_fixed_book_costs_sku_id  (sku_id => skus.id)
#
class FixedBookCost < LegacyRecord

  belongs_to :sku

end
