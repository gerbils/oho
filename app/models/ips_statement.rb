
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

  belongs_to :upload_wrapper, dependent: :destroy, optional: true

  has_many :details, class_name: "IpsStatementDetail", dependent: :destroy
  has_many :ips_detail_lines, through: :details
  has_many :expenses, -> { where(section: SECTION_EXPENSE) }, class_name: "IpsStatementDetail"
  has_many :revenues, -> { where(section: SECTION_REVENUE) }, class_name: "IpsStatementDetail"
  has_many :revenue_lines, through: :revenues, source: :ips_detail_lines

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

  MARKETING_AND_MISC = "Distribution: Marketing & Misc."


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

  def estimated_royalties
    IpsUploadEstimate.estimate(self)
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

  # RoyaltyItem generation interface

  def set_import_status!(status, imported_at: Time.current, message: nil)
    self.status = status
    self.imported_at = imported_at
    self.status_message = message
    self.save!
  end

  class Result
    attr_reader :lines
    def initialize
      @lines = {}
    end

    def add(proto_ri)
      sku_id = proto_ri.sku_id
      line = (@lines[sku_id] ||= {})
      channel = proto_ri.description
      if line[channel]
        line[channel].merge(proto_ri)
      else
        line[channel] = proto_ri
      end
      self
    end

    def flatten
      result = []
      @lines.each_value do |channel|
        result.concat(channel.values)
      end
      result
    end
  end

  def statement_lines
    result = Result.new
    non_sku_total = BigDecimal("0.00")
    non_sku_total += accumulate_revenues(result)
    non_sku_total += accumulate_expenses(result)
    non_sku_total += accumulate_non_sku_specific(result)
    write_non_sku_values(non_sku_total, result) unless non_sku_total.zero?
    result.flatten
  end

  private

  # revenue numbers allow for returns, and have two separate columns on the
  # statement. Expense lines are accumulated in a single column, plus and minus
  #
  def accumulate_revenues(result)
    non_sku_total = BigDecimal("0.00")
    revenues.each do |detail|
      channel = revenue_channel_for(detail)
      detail.ips_detail_lines.each do |line|
        if line.sku_id.blank?
          non_sku_total += line.amount
        else
          proto_ri = ProtoRoyaltyLine.new(
            sku_id:        line.sku_id,
            item_type:     RoyaltyItem::IPS_REVENUE_TYPE,
            description:   channel,
            free_units:    0,
            paid_units:    line.amount > 0 ? line.quantity  : 0,
            paid_amount:   line.amount > 0 ? line.amount    : 0,
            return_units:  line.amount < 0 ? line.quantity  : 0,
            return_amount: line.amount < 0 ? line.amount    : 0,
            book_basis:    0,
            date:          self.month_ending,
            applies_to:    RoyaltyItem::APPLIES_TO_BOTH,
            source_type:   self.class.name,
            source_id:     self.id,
          )
          result.add(proto_ri)
        end
      end
    end
    non_sku_total
  end

  def accumulate_expenses(result)
    non_sku_total = BigDecimal("0.00")
    expenses.each do |detail|
      channel = expense_channel_for(detail)
      detail.ips_detail_lines.each do |line|
        if line.sku_id.nil?
          non_sku_total += line.amount
        else
          proto_ri = ProtoRoyaltyLine.new(
            sku_id:        line.sku_id,
            item_type:     RoyaltyItem::IPS_EXPENSE_TYPE,
            description:   channel,
            free_units:    0,
            paid_units:    0,
            paid_amount:   0,
            return_units:  line.quantity,
            return_amount: line.amount,
            book_basis:    0,
            date:          self.month_ending,
            applies_to:    RoyaltyItem::APPLIES_TO_BOTH,
            source_type:   self.class.name,
            source_id:     self.id,
          )

          if proto_ri.return_amount > 0
            proto_ri.paid_amount = proto_ri.return_amount
            proto_ri.paid_units = proto_ri.return_units
            proto_ri.return_amount = 0
            proto_ri.return_units = 0
            proto_ri.description += " (refund)"
          end

          result.add(proto_ri)
        end
      end
    end
    non_sku_total
  end

  def accumulate_non_sku_specific(result)
    total_misc = BigDecimal("0.0000")

    details.each do |detail|
      next if detail.ips_detail_lines.any?
      total_misc += detail.due_this_month
    end

    total_misc
  end

  # Any amounts that are not associated with a specific sku are distributed across them all

  def write_non_sku_values(total_misc, result)
    skus    = Set.new(ips_detail_lines.where("sku_id is not null").pluck(:sku_id).uniq)
    per_sku = (total_misc / skus.size) #.round(2)
    skus.each do |sku_id|
        proto_ri = ProtoRoyaltyLine.new(
          sku_id:        sku_id,
          item_type:     RoyaltyItem::IPS_EXPENSE_TYPE,
          description:   MARKETING_AND_MISC,
          free_units:    0,
          paid_units:    0,
          paid_amount:   0,
          return_units:  0,
          return_amount: per_sku, # + delta,
          book_basis:    0,
          date:          self.month_ending,
          applies_to:    RoyaltyItem::APPLIES_TO_BOTH,
          source_type:   self.class.name,
          source_id:     self.id,
        )
        result.add(proto_ri)
      end
  end



  def revenue_channel_for(rev_detail)
    case rev_detail.subsection
    when /sales/i
      case rev_detail.detail
      when /canadian/i, /international/i, /UK/
        "Distribution: International Sales"
      when /domestic/i
        "Distribution: Domestic Sales"
      when /ebook/i
        "Distribution: Ebook Sales"
      else
        raise ArgumentError, "Unknown revenue detail #{rev_detail.detail.inspect} for subsection #{rev_detail.subsection.inspect}"
      end
    when /returns/i
      case rev_detail.detail
      when /domestic/i
        "Distribution: Domestic Returns"
      when /international/i
        "Distribution: International Returns"
      when /ebook/i
        "Distribution: Ebook Returns"
      else
        raise ArgumentError, "Unknown revenue detail #{rev_detail.detail.inspect} for subsection #{rev_detail.subsection.inspect}"
      end
    else
      raise ArgumentError, "Unknown revenue category #{rev_detail.subsection.inspect}"
    end
  end

  def expense_channel_for(detail)
    case detail.subsection
    when /freight/i
      "Distribution: Fulfillment"
    when /distribution\s?fees/i
      "Distribution: Fees"
    when /lightning source/i
      "Printing costs"
    when /other fees/i
      MARKETING_AND_MISC
    else
      raise ArgumentError, "Unknown expense category #{detail.subsection.inspect}"
    end
  end

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
