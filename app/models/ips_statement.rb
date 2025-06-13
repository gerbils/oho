
# == Schema Information
#
# Table name: ips_statements
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(10, 2)   default(0.0)
#  gross_returns_total :decimal(10, 2)   default(0.0)
#  gross_sales_total   :decimal(10, 2)   default(0.0)
#  imported_at         :datetime
#  month_ending        :date             not null
#  net_client_earnings :decimal(10, 2)   default(0.0)
#  net_sales           :decimal(10, 2)   default(0.0)
#  revenue             :decimal(10, 2)   default(0.0)
#  status              :string(255)      not null
#  status_message      :string(255)
#  total_chargebacks   :decimal(10, 2)   default(0.0)
#  total_expenses      :decimal(10, 2)   default(0.0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  upload_wrapper_id   :bigint           not null
#
# Indexes
#
#  index_ips_statements_on_upload_wrapper_id  (upload_wrapper_id)
#
# Foreign Keys
#
#  fk_rails_...  (upload_wrapper_id => upload_wrappers.id)
#
class IpsStatement < ActiveRecord::Base

  include ActionView::RecordIdentifier   # for dom_id

  belongs_to :upload_wrapper, dependent: :destroy

  has_many :details, class_name: "IpsStatementDetail", dependent: :destroy
  has_many :ips_revenue_lines, through: :details
  has_many :expenses, -> { where(section: SECTION_EXPENSE) }, class_name: "IpsStatementDetail"
  has_many :revenues, -> { where(section: SECTION_REVENUE) }, class_name: "IpsStatementDetail"

  SECTION_REVENUE = "REVENUE"
  SECTION_EXPENSE = "EXPENSE"
  SECTIONS = [SECTION_REVENUE, SECTION_EXPENSE]

  STATUS_IMPORTED       = 'Complete'
  STATUS_FAILED_IMPORT  = 'Failed import'
  STATUS_FAILED_UPLOAD  = 'Failed upload'
  STATUS_INCOMPLETE     = 'Incomplete'
  STATUS_PROCESSING     = 'Processing'
  STATUS_UPLOADED       = 'Uploaded'
  STATUS_UPLOAD_PENDING = 'Pending'

  STATII = [
    STATUS_FAILED_IMPORT,
    STATUS_FAILED_UPLOAD,
    STATUS_IMPORTED,
    STATUS_INCOMPLETE,
    STATUS_PROCESSING,
    STATUS_UPLOADED,
    STATUS_UPLOAD_PENDING,
  ]

  # validates :month_ending,        presence: true
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
    # :month_ending,
    :upload_wrapper_id,
    presence: true
  )


  # after_create_commit :add_to_index_page
  after_update_commit :update_index_page

  def self.new_with_upload(upload)
    new(
      upload_wrapper: upload,
      status: STATUS_UPLOAD_PENDING,
      status_message: nil
    )
  end

  def self.stats
    query = %{
      SELECT count(*), sum(net_client_earnings), status FROM ips_statements GROUP BY status
    }
    connection.execute(query).map do |(count, total, status)|
      { count:, total:, status: }
    end
  end

  def oho_errors
    OhoError.for_object(self)
  end

  def mark_if_complete
    if details.empty?
      self.status = STATUS_INCOMPLETE
      return
    end

    completed_details = details.where('ips_detail_lines_count > 0').count
    all_details = details.count

    if completed_details == all_details
      self.status = STATUS_UPLOADED
      self.status_message = "Can be imported"
    else
      self.status = STATUS_INCOMPLETE
      self.status_message = "#{"subreport".pluralize(all_details - completed_details)} need to be uploaded"
    end
    self.save!
  end

  def get_matching_details_for_total(total)
    details.where(due_this_month: total)
  end

  private

  # def add_to_index_page
  #   broadcast_prepend_to(
  #     "ips-royalty-index",
  #     target: "upload-list",
  #     partial: "royalties/ips/statements/statement", locals: { statement: self }
  #   )
  # end

  def update_index_page
    broadcast_replace_to(
      "ips-royalty-index",
      target: dom_id(self),
      partial: "royalties/ips/statements/statement", locals: { statement: self }
    )
  end

end
