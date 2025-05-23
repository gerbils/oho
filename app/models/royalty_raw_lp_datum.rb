class RoyaltyRawLpDatum < ActiveRecord::Base

  belongs_to :upload
  validates :upload_id,         presence: true
  validates :isbn,              presence: true
  validates :title,             presence: true
  validates :publisher,         presence: true
  validates :author,            presence: true
  validates :channel,           presence: true
  validates :sales,             presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_rate,   presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_earned, presence: true, numericality: { greater_than_or_equal_to: 0 }

end
