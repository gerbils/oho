
# == Schema Information
#
# Table name: ips_statement_details
#
#  id                     :bigint           not null, primary key
#  basis                  :string(255)
#  basis_for_charge       :decimal(12, 4)   not null
#  detail                 :string(255)      not null
#  due_this_month         :decimal(12, 4)   not null
#  factor_or_rate         :decimal(6, 4)    not null
#  ips_detail_lines_count :integer          default(0), not null
#  month_due              :date
#  reconciled             :boolean          default(FALSE)
#  section                :string(255)      not null
#  subsection             :string(255)      not null
#  uploaded_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  ips_statement_id       :bigint           not null
#  upload_wrapper_id      :bigint
#
# Indexes
#
#  index_ips_statement_details_on_ips_statement_id   (ips_statement_id)
#  index_ips_statement_details_on_upload_wrapper_id  (upload_wrapper_id)
#
# Foreign Keys
#
#  fk_rails_...  (ips_statement_id => ips_statements.id)
#  fk_rails_...  (upload_wrapper_id => upload_wrappers.id)
#
#  fk_rails_...  (ips_statement_id => ips_statements.id)

class IpsStatementDetail < ActiveRecord::Base

  include ActionView::RecordIdentifier   # for dom_id
  extend  Helpers::DateTime
  include Helpers::DateTime

  SECTION_REVENUE = "REVENUE"
  SECTION_EXPENSE = "EXPENSE"
  SECTIONS = [SECTION_REVENUE, SECTION_EXPENSE]

  belongs_to :upload_wrapper, optional: true
  belongs_to :ips_statement, counter_cache: true
  has_many   :ips_detail_lines, dependent: :destroy
  has_many   :ips_reconciliations, dependent: :destroy
  has_many   :ips_payment_advice_lines, through: :ips_reconciliations

  validates :section, inclusion: { in: SECTIONS }
  validates :subsection, presence: true
  validates :detail, presence: true

  validates :basis_for_charge, numericality: true
  validates :factor_or_rate,   numericality: true
  validates :due_this_month,   numericality: true

  before_save :normalize_date
  after_save :maybe_update_status

  def self.match_with_payment(invoice_date, invoice_number, paid_amount)
    date = first_of_month(invoice_date)
    possibles = where(
      due_this_month: paid_amount,
      reconciled:     false,
    )
    return possibles if possibles.length <= 1

    # given multiple matches, try using the month due. (This isn't in the original search because
    # they sometimes slip a month).

    maybe = possibles.where(month_due: date)
    if maybe.length == 1
      maybe
    else
      possibles
    end
  end

  # This gets called when we have a payment that doesn't match a statement
  # line. We look for combinations od lines that add up to the paid amount.
  # This is used for co-op payments, where we don't have a statement line.

  def self.match_with_combinations(invoice_date, invoice_number, paid_amount)
    statement = IpsStatement.find_by_month_ending(invoice_date)
    fail("Can't find statement for month ending #{invoice_date}") unless statement

    # we don't want to match against reconciled lines, so we filter those out.
    # We also filter out lines that are not due this month.
    #
    # NOTE: It's greater than because the amounts are negative
    possibles = statement.details.where("due_this_month > ? AND not reconciled", paid_amount).to_a

    # no ability to create combinations.
    return [] if possibles.length < 2

    # this is O(N^2), but we're probably looking at at most 20 lines, and its
    # all in memory
    # we return all possible combinations that match and let God sort them out.
    matches = []
    while possibles.length > 1
      first = possibles.shift
      possibles.each do |second|
        if first.due_this_month + second.due_this_month == paid_amount
          matches << [first, second]
        end
      end
    end

    matches
  end

  def self.revenue_details
    where(section: SECTION_REVENUE)
  end

  def self.expense_details
    where(section: SECTION_EXPENSE)
  end

  def ready_to_import?
    self.uploaded_at? || self.detail == "Co-Op"   # ugly, but there's no upload for co-op
  end

  private

  def normalize_date
    self.month_due = first_of_month(self.month_due) if self.month_due
  end

  def maybe_update_status
    if saved_change_to_uploaded_at?
       broadcast_replace_to(
         dom_id(ips_statement, :show),
         target: dom_id(self, :status),
         partial: "royalties/ips/statements/detail_status", locals: { statement: self.ips_statement, item: self }
       )
    end
  end
end
