# == Schema Information
#
# Table name: ips_payment_advice_lines
#
#  id                      :bigint           not null, primary key
#  discount_taken          :decimal(10, 2)
#  gross_amount            :decimal(10, 2)
#  invoice_date            :date
#  invoice_number          :string(255)
#  paid_amount             :decimal(10, 2)
#  status                  :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  ips_payment_advice_id   :bigint           not null
#  ips_statement_detail_id :bigint
#  voucher_id              :string(255)
#
# Indexes
#
#  index_ips_payment_advice_lines_on_ips_payment_advice_id    (ips_payment_advice_id)
#  index_ips_payment_advice_lines_on_ips_statement_detail_id  (ips_statement_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (ips_payment_advice_id => ips_payment_advices.id)
#  fk_rails_...  (ips_statement_detail_id => ips_statement_details.id)
#
class IpsPaymentAdviceLine < ApplicationRecord
  include ActionView::RecordIdentifier   # for dom_id

  STATUS_UNRECONCILED = 'Unreconciled'
  STATUS_RECONCILED = 'Reconciled'
  STATUS_TOO_MANY_MATCHES = 'Too many matches'
  STATII = [
    STATUS_UNRECONCILED,
    STATUS_RECONCILED,
    STATUS_TOO_MANY_MATCHES
  ]

  after_save :maybe_update_status, unless: -> { Rails.env.test? }
  after_save :update_parent_discounts_flag, if: :saved_change_to_discount_taken?
  after_destroy :update_corresponding_detail_line, unless: -> { Rails.env.test? }

  belongs_to :ips_payment_advice
  has_many   :ips_reconciliations, dependent: :destroy
  has_many   :ips_statement_details, through: :ips_reconciliations

  validates_presence_of :invoice_number
  validates_presence_of :invoice_date
  validates_presence_of :voucher_id
  validates_presence_of :gross_amount, numericality: true
  validates_presence_of :discount_taken, numericality: true
  validates_presence_of :paid_amount, numericality: true
  validates             :status, inclusion: { in: STATII }

  def reconciled?
    ips_reconciliations.present?
  end

  private

  def maybe_update_status
    broadcast_replace_to(
      dom_id(ips_payment_advice, :show),
      target: dom_id(self),
      partial: "royalties/ips/payments/payment_advice_line", locals: { line: self, discounts_taken: ips_payment_advice.discounts_taken, focus_line: self.id }
    )

      broadcast_replace_to(
        dom_id(ips_payment_advice, :show),
        target: "next-steps",
        partial: "royalties/ips/payments/next_steps", locals: { payment: ips_payment_advice }
      )
  end

  def update_corresponding_detail_line
    if ips_statement_detail
      ips_statement_detail.update!(reconciled: false)
    end
  end

  def update_parent_discounts_flag
    ips_payment_advice.update!(discounts_taken: true) unless discount_taken.zero?
  end
end
