
# == Schema Information
#
# Table name: ips_statements
#
#  id                          :bigint           not null, primary key
#  expenses                    :decimal(12, 4)   default(0.0)
#  gross_returns_total         :decimal(12, 4)   default(0.0)
#  gross_sales_total           :decimal(12, 4)   default(0.0)
#  import_free_units           :integer          default(0)
#  import_paid_amount          :decimal(12, 4)   default(0.0)
#  import_paid_units           :integer          default(0)
#  import_return_amount        :decimal(12, 4)   default(0.0)
#  import_return_units         :integer          default(0)
#  imported_at                 :datetime
#  ips_statement_details_count :integer          default(0)
#  month_ending                :date             default(Mon, 01 Jan 1000)
#  net_client_earnings         :decimal(12, 4)   default(0.0)
#  net_sales                   :decimal(12, 4)   default(0.0)
#  revenue                     :decimal(12, 4)   default(0.0)
#  status                      :string(255)      not null
#  status_message              :string(255)
#  total_chargebacks           :decimal(12, 4)   default(0.0)
#  total_expenses              :decimal(12, 4)   default(0.0)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  upload_wrapper_id           :bigint           not null
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

  belongs_to :upload_wrapper, dependent: :destroy, optional: true

  has_many :details, class_name: "IpsStatementDetail", dependent: :destroy
  has_many :ips_detail_lines, through: :details
  has_many :expenses, -> { where(section: SECTION_EXPENSE) }, class_name: "IpsStatementDetail"
  has_many :revenues, -> { where(section: SECTION_REVENUE) }, class_name: "IpsStatementDetail"
  has_many :revenue_lines, through: :revenues, source: :ips_detail_lines

  SECTION_REVENUE = "REVENUE"
  SECTION_EXPENSE = "EXPENSE"
  SECTIONS = [SECTION_REVENUE, SECTION_EXPENSE]

  STATUS_IMPORTED       = 'Imported'
  STATUS_PARTIALLY_IMPORTED = 'Partially imported'
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
    STATUS_PARTIALLY_IMPORTED,
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
    presence: true
  )

  unless Rails.env.test?
    validates :upload_wrapper_id, presence: true
  end

  # after_create_commit :add_to_index_page
  after_update_commit :update_index_page

  def self.new_with_upload(upload)
    new(
      upload_wrapper: upload,
      status: STATUS_UPLOAD_PENDING,
      status_message: nil
    )
  end

  def may_be_deleted?
    ![STATUS_PARTIALLY_IMPORTED, STATUS_IMPORTED].include?(status)
  end

  def status
    case current_status = super()
    when STATUS_UPLOADED
      split = details.group(:reconciled).count
      if (split[true] || 0).zero?
        STATUS_UPLOADED
      elsif (split[false] || 0).zero?
        STATUS_IMPORTED
      else
        STATUS_PARTIALLY_IMPORTED
      end
    else
      current_status
    end
  end

  def self.stats
    query = %{
      SELECT count(*), sum(net_client_earnings), status FROM ips_statements GROUP BY status
    }
    connection.execute(query).map do |(count, total, status)|
      { count:, total:, status: }
    end
  end

  def ready_to_import?
    !self.imported_at? && details.all?(&:ready_to_import?)
  end

  def oho_errors
    OhoError.for_object(self)
  end

  def clear_oho_errors
    OhoError.clear_errors(self)
  end

  def get_matching_details_for_total(total)
    details.where('abs(due_this_month - ?) <= 0.011', total)
  end


  def update_index_page
    broadcast_replace_to(
      "ips-royalty-index",
      target: dom_id(self),
      partial: "royalties/ips/statements/statement", locals: { statement: self }
    )
  end

end
