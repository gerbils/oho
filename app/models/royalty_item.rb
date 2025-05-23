class RoyaltyItem < LegacyRecord

  belongs_to :sku
  belongs_to :source, polymorphic: true

  ONLINE_TYPE = "Online"
  LP_TYPE     = "LP"

  DISTRIBUTOR_TYPE = "ORA"
  AUTHOR_PURCHASE_TYPE = "Author"
  INTL_RIGHTS_TYPE = "IntlRights"
  INTL_ROYALTY_TYPE = "IntlRylty"
  OTHER_TYPE = "Other"

  APPLIES_TO_BOTH = 0
  APPLIES_TO_AUTHOR_ONLY = 1
  APPLIES_TO_EDITOR_ONLY = 2

  APPLIES_TO_AS_SELECT_LIST = [
    ["EDITOR + AUTHOR", APPLIES_TO_BOTH],
    ["AUTHOR ONLY", APPLIES_TO_AUTHOR_ONLY],
    ["EDITOR ONLY", APPLIES_TO_EDITOR_ONLY],
  ]

  SPECIAL_TYPES = [INTL_RIGHTS_TYPE, INTL_ROYALTY_TYPE, OTHER_TYPE]

  validates_presence_of :date, :sku_id, :item_type, :description
  validates_presence_of :free_units
  validates_presence_of :paid_units, :paid_amount
  validates_presence_of :return_units, :return_amount
  validates_presence_of :book_basis

  validates_numericality_of :free_units, :paid_units, :return_units, :only_integer => true
  validates_numericality_of :paid_amount, :return_amount, :applies_to

  def add_in(other)
    cost = self.production_cost
    self.free_units += other.free_units
    self.paid_units += other.paid_units
    self.paid_amount += other.paid_amount
    self.return_units += other.return_units
    self.return_amount += other.return_amount
    cost += other.production_cost
    if self.paid_units > 0
      self.book_basis = (cost / self.paid_units).round(10)
    else
      self.book_basis = 0
    end
  end

  def production_cost
    self.book_basis * self.paid_units
  end

end
