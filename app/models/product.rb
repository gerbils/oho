class Product < LegacyRecord
  has_many :skus, -> { order("released_on asc") }

  has_many :author_sku_royalties, 
           -> { order("author_sku_royalties.user_id asc") },
           :through => :skus, 
           :source => :author_sku_royalties
    
  has_many :authors, -> { distinct }, through: :author_sku_royalties, source: :user

  def Product.string_with_edition(title, edition)
    if edition > 1
      "#{title} (#{edition.ordinalize} edition)"
    else
      title
    end
  end

  def title_with_edition
    Product.string_with_edition(self.title, self.edition)
  end

end

