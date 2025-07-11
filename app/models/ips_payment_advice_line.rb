class IpsPaymentAdviceLine < ApplicationRecord
  STATUS_UNRECONCILED = 'Unreconciled'
  STATUS_RECONCILED = 'Reconciled'
  STATUS_TOO_MANY_MATCHES = 'Too many matches'
  STATII = [
    STATUS_UNRECONCILED,
    STATUS_RECONCILED,
    STATUS_TOO_MANY_MATCHES
  ]


  belongs_to :ips_payment_advice
  belongs_to :ips_statement_detail, optional: true

  validates_presence_of :invoice_number
  validates_presence_of :invoice_date
  validates_presence_of :voucher_id
  validates_presence_of :gross_amount, numericality: true
  validates_presence_of :discount_taken, numericality: true
  validates_presence_of :paid_amount, numericality: true
  validates             :status, inclusion: { in: STATII }

  def reconciled?
    ips_statement_detail.present?
  end
end
