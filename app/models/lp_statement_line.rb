# == Schema Information
#
# Table name: royalty_raw_lp_data
#
#  id                :bigint           not null, primary key
#  author            :string(255)      not null
#  channel           :string(255)      not null
#  commission_earned :decimal(10, 2)   not null
#  commission_rate   :decimal(5, 2)    not null
#  e_isbn            :string(255)
#  isbn              :string(255)      not null
#  publisher         :string(255)      not null
#  sales             :decimal(10, 2)   not null
#  title             :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  sku_id            :bigint
#  upload_id         :bigint           not null
#
# Indexes
#
#  index_royalty_raw_lp_data_on_isbn       (isbn)
#  index_royalty_raw_lp_data_on_sku_id     (sku_id)
#  index_royalty_raw_lp_data_on_upload_id  (upload_id)
#
# Foreign Keys
#
#  fk_rails_...  (upload_id => uploads.id)
#
class LpStatementLine < ActiveRecord::Base

  belongs_to :sku

  validates :sku,               presence: true
  validates :isbn,              presence: true
  validates :title,             presence: true
  validates :publisher,         presence: true
  validates :author,            presence: true
  validates :sales,             presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_rate,   presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_earned, presence: true, numericality: { greater_than_or_equal_to: 0 }

end
