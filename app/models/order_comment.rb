# == Schema Information
#
# Table name: order_comments
#
#  id         :integer          not null, primary key
#  comment    :text(65535)
#  created_at :datetime
#  order_id   :integer
#  user_id    :integer
#
# Indexes
#
#  fk_order_comments_order_id  (order_id)
#  fk_order_comments_user_id   (user_id)
#
# Foreign Keys
#
#  fk_order_comments_order_id  (order_id => orders.id)
#  fk_order_comments_user_id   (user_id => users.id)
#
class OrderComment < LegacyRecord
  belongs_to :user, optional: true
  belongs_to :order
  
  def posted_by_name
    if self.user
      self.user.name
    else
      "anon"
    end
  end
end

