class Coupon < LegacyRecord

  has_many :discount_items

  ACTIONS = %w(DEDUCT_AMOUNT DEDUCT_PERCENT)

  ANY_OF     = "ANY_OF"
  EXCLUDING  = "EXCLUDING"
  EVERYTHING = "EVERYTHING"

  APPLIES_TO = [ ANY_OF, EXCLUDING, EVERYTHING ]

  validates_presence_of   :code
  validates_uniqueness_of :code
  validates_inclusion_of  :applies_to, :in => APPLIES_TO
  validates_inclusion_of  :action, :in => ACTIONS

  validate :validate_amount

  before_create :set_use_key

  def self.from_hash(hash)
    amount, action =
      if hash.has_key?("percentage_discount")
        [ hash["percentage_discount"], 'DEDUCT_PERCENT' ]
      else
        [ hash["fixed_discount"], 'DEDUCT_AMOUNT' ]
      end

    new(
      code: hash["code"],
      description: hash["name"],
      action: action,
      amount: amount,
      external_only: hash["skus"].length.zero?,
      applies_to: ANY_OF,
      sku_list: hash["skus"].map {|code| "#{code}-P-00"}.join(", "),
      use_count: 0,
      expires_at: hash["expires_at"],
    )
  end


  def same_as?(other)
      [
        :code,
      :description,
      :action,
      :amount,
      :external_only,
      :applies_to,
      :sku_list,
      :use_count,
      :expires_at,
      ].each do |field|
        mine = self[:field]
        theirs = other[:field]
        unless mine == theirs
          STDERR.puts "Coupon field #{field} differs\n:mine:   #{mine.inspect}\nother:  #{theirs.inspect}"
          return false
        end
      end
      true
  end

  private

  def validate_amount
    if amount.nil? || amount <= 0
      errors.add(:amount, "must be positive") unless !errors[:amount].empty?
    end
  end
  

  def set_use_key
    self.use_key = Time.now.to_i
  end



end
