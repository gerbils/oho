# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  ip_address :string(255)
#  user_agent :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
class Session < ApplicationRecord
  belongs_to :user
end
