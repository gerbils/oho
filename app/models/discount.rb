# == Schema Information
#
# Table name: discounts
#
#  id          :integer          not null, primary key
#  action      :string(255)
#  amount      :decimal(8, 2)    default(0.0)
#  description :text(65535)
#  name        :string(255)
#  created_at  :datetime
#
class Discount < LegacyRecord

end
