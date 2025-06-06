# == Schema Information
#
# Table name: author_sku_royalties
#
#  id              :integer          not null, primary key
#  is_editor       :boolean          default(FALSE)
#  royalty_percent :decimal(8, 6)    not null
#  sku_id          :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  fk_author_sku_royalties_sku_id       (sku_id)
#  only_one_royalty_per_author_per_sku  (user_id,sku_id) UNIQUE
#
# Foreign Keys
#
#  fk_author_sku_royalties_sku_id   (sku_id => skus.id)
#  fk_author_sku_royalties_user_id  (user_id => users.id)
#
class AuthorSkuRoyalty < LegacyRecord

  belongs_to :sku
  belongs_to :user
  
end

