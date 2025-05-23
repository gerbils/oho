class User < LegacyRecord
  has_one :author_details, :class_name => "Author", :foreign_key => "user_id"
  has_many :author_calendar_items
  has_many :author_sku_royalties
  has_many :author_royalty_payments

  has_many :skus, through: :author_sku_royalties
  has_many :titles, -> { distinct }, through: :skus, source: :product

  def is_author_or_above?
      author? || editor? || series_editor? || admin?  || support? || acquisitions?
  end

  def acquisitions?
    email == "margaret.eldridge@pragprog.org"
  end

  def royalties_paid_before(date)
    author_royalty_payments.actual_payments.where("paid_on < ?", date)
  end

  def find_available_royalty_dates(future_month_offset = 0)
    start = find_first_royalty_date
    return [] unless start
    start = Date.civil(start.year, start.month)
    now = Time.now
    now = Date.civil(now.year, now.month) << 1 - future_month_offset

    result = []
    while start <= now
      result << start
      start = start >> 1
    end
    result
  end

  # What's the first date we had a royalty transaction for this author
  # We look for a royalty item of fixed cost associated with one of the author's skus
  def find_first_royalty_date
    ri = RoyaltyItem.find_by_sql([
      "select min(ri.date) as date
         from royalty_items ri, author_sku_royalties asr
        where asr.user_id = ?
          and ri.sku_id = asr.sku_id",
      self.id,
    ])

    ri_date = ri.first.date

    fixed = FixedBookCost.find_by_sql([
      "select min(fbc.created_on) as created_on
         from fixed_book_costs fbc, author_sku_royalties asr
        where asr.user_id = ?
          and fbc.sku_id = asr.sku_id",
      self.id,
    ])

    fixed_date = fixed.first.created_on

    case
    when ri_date.nil? && fixed_date.nil?
      nil
    when ri_date.nil?
      fixed_date
    when fixed_date.nil?
      ri_date
    else
      if ri_date < fixed_date.to_time
        ri_date
      else
        fixed_date
      end
    end
  end


#   ╭────────────────────────────────────────────────────────────────────────╮
#   │                 This is the authentication-zero stuff                  │
#   ╰────────────────────────────────────────────────────────────────────────╯

  has_secure_password
  has_many :sessions, dependent: :destroy
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 8 }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end
end

