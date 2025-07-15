
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

  belongs_to :upload_wrapper, optional: false
  belongs_to :ips_statement, counter_cache: true
  has_many   :ips_detail_lines, dependent: :destroy
  has_one    :ips_payment_advice_line, dependent: :nullify

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
