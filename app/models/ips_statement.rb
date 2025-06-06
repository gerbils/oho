
# == Schema Information
#
# Table name: raw_ips_statements
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(10, 2)   default(0.0)
#  gross_returns_total :decimal(10, 2)   default(0.0)
#  gross_sales_total   :decimal(10, 2)   default(0.0)
#  month_ending        :date             not null
#  net_client_earnings :decimal(10, 2)   default(0.0)
#  net_sales           :decimal(10, 2)   default(0.0)
#  revenue             :decimal(10, 2)   default(0.0)
#  total_chargebacks   :decimal(10, 2)   default(0.0)
#  total_expenses      :decimal(10, 2)   default(0.0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  upload_id           :bigint           not null
#
# Indexes
#
#  index_raw_ips_statements_on_upload_id  (upload_id)
#
# Foreign Keys
#
#  fk_rails_...  (upload_id => uploads.id)
#
class IpsStatement < ActiveRecord::Base
  belongs_to :upload_wrapper, dependent: :destroy

  has_many :details, class_name: "IpsStatementDetail", dependent: :destroy
  has_many :expenses, -> { where(section: SECTION_EXPENSE) }, class_name: "IpsStatementDetail"
  has_many :revenues, -> { where(section: SECTION_REVENUE) }, class_name: "IpsStatementDetail"

  SECTION_REVENUE = "REVENUE"
  SECTION_EXPENSE = "EXPENSE"
  SECTIONS = [SECTION_REVENUE, SECTION_EXPENSE]

  STATUS_PENDING       = 'Pending'
  STATUS_INCOMPLETE    = 'Incomplete'
  STATUS_PROCESSING    = 'Processing'
  STATUS_COMPLETE      = 'Complete'
  STATUS_FAILED_UPLOAD = 'Failed upload'
  STATUS_FAILED_IMPORT = 'Failed import'
  STATII = [
    STATUS_PENDING, STATUS_INCOMPLETE, STATUS_PROCESSING, STATUS_COMPLETE,
    STATUS_FAILED_UPLOAD, STATUS_FAILED_IMPORT
  ]

  validates :month_ending,        presence: true
  validates :gross_sales_total,   numericality: true
  validates :gross_returns_total, numericality: true
  validates :net_sales,           numericality: true
  validates :total_chargebacks,   numericality: true
  validates :total_expenses,      numericality: true
  validates :net_client_earnings, numericality: true
  validates :status,              inclusion: { in: STATII }

  validates(
    :gross_returns_total,
    :gross_sales_total,
    :net_client_earnings,
    :net_sales,
    :total_chargebacks,
    :total_expenses,
    :month_ending,
    :upload_wrapper_id,
    presence: true
  )

  def self.stats
    query = %{
      SELECT count(*), sum(net_client_earnings), status FROM ips_statements GROUP BY status
    }
    connection.execute(query).map do |(count, total, status)|
      { count:, total:, status: }
    end

  end

end
