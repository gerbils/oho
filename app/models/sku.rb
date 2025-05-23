class Sku < LegacyRecord
  belongs_to :product
  has_many :author_sku_royalties, -> { order("user_id asc") }
  has_many :fixed_book_costs

  has_many :royalty_items do

    def for_someone(applies_to, on_or_after, before)
      where("(applies_to = ? or applies_to = ?) and date >= ? and date < ?",
                           RoyaltyItem::APPLIES_TO_BOTH, applies_to, on_or_after, before)
    end

    private :for_someone

    def for_editors(on_or_after, before)
      for_someone(RoyaltyItem::APPLIES_TO_EDITOR_ONLY, on_or_after, before)
    end

    def for_authors(on_or_after, before)
      for_someone(RoyaltyItem::APPLIES_TO_AUTHOR_ONLY, on_or_after, before)
    end
  end

  # ----

  def media
    @media ||= begin
                 m = read_attribute(:media)
                 if new_record? && m.blank?
                   nil
                 else
                   Media.for_code(m)
                 end
               end
  end

  def variant_name
    if media.other? && !part_name.blank?
      part_name
    else
      name = media.name
      if name == Media::BETA_ON_PAPER && !product.beta?
        "Paper book"
      else
        name
      end
    end
  end

  # OPTIMIZE
  def product_title
    self.product ? self.product.title_with_edition : self.sku
  end

  # OPTIMIZE
  def product_name
    name = "#{self.product_title} "
    name << "#{self.part_name} " unless self.part_name.blank?
    name << "(#{variant_name})"
    name
  end

  # OPTIMIZE
  def product_code
    self.product.code
  end

  def variant_name
    if media.other? && !part_name.blank?
      part_name
    else
      name = media.name
      if name == Media::BETA_ON_PAPER && !product.beta?
        "Paper book"
      else
        name
      end
    end
  end


end

