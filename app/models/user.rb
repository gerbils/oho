# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  accepted_terms_at         :datetime
#  activated_from_ip         :string(255)
#  activation_sent_at        :datetime
#  admin                     :boolean          default(FALSE)
#  allow_order_status_emails :boolean          default(TRUE)
#  allows_marketing_email    :boolean          default(FALSE)
#  author                    :boolean          default(FALSE)
#  bio                       :text(65535)
#  created_from_ip           :string(255)
#  editor                    :boolean          default(FALSE)
#  email                     :string(255)
#  email_subscription        :boolean
#  email_subscription_date   :datetime
#  frights                   :boolean
#  hashed_password           :string(255)
#  hotmail                   :integer
#  is_potential_blaggard     :string(255)
#  is_tax_exempt             :boolean          default(FALSE)
#  kindle_name               :string(255)
#  last_login_at             :datetime
#  last_seen_at              :datetime
#  login_count               :integer          default(0)
#  login_key                 :string(255)
#  login_key_expires_at      :datetime
#  name                      :string(255)
#  not_interested_in_kindle  :boolean          default(FALSE)
#  notify_using_email        :boolean          default(TRUE)
#  over_18                   :boolean          default(TRUE)
#  password_digest           :string(255)
#  posts_count               :integer          default(0)
#  promotion_last_seen_at    :datetime
#  provider                  :string(255)
#  rss_feed_url              :string(255)
#  salt                      :string(255)
#  series_editor             :boolean
#  stored_account_number     :string(255)
#  subscribed_rss_at         :datetime
#  support                   :boolean          default(FALSE)
#  twitter_name              :string(255)
#  uid                       :string(255)
#  upload_filename           :string(255)
#  uploaded_at               :datetime
#  verified                  :boolean
#  website_url               :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  last_seen_promotion_id    :integer
#  publisher_id              :integer
#  shipping_location_id      :integer
#
# Indexes
#
#  fk_users_publisher_id                 (publisher_id)
#  fk_users_shipping_location_id         (shipping_location_id)
#  index_users_on_email                  (email)
#  index_users_on_last_seen_at           (last_seen_at)
#  index_users_on_stored_account_number  (stored_account_number)
#
# Foreign Keys
#
#  fk_users_publisher_id          (publisher_id => publishers.id)
#  fk_users_shipping_location_id  (shipping_location_id => shipping_locations.id)
#
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

