class IpsPaymentAdvice < ApplicationRecord
  include ActionView::RecordIdentifier   # for dom_id

  has_many :ips_payment_advice_lines
  belongs_to :upload_wrapper, dependent: :destroy, optional: true


  validates :pay_cycle, presence: true, on: :update
  validates :pay_cycle_seq_number, presence: true, on: :update
  validates :payment_reference, presence: true, on: :update
  validates :payment_date, presence: true, on: :update
  validates :total_amount, presence: true, numericality: true, on: :update

  after_update_commit :update_index_page

  STATUS_FAILED_IMPORT  = 'Failed import'
  STATUS_FAILED_UPLOAD  = 'Failed upload'
  STATUS_IMPORTED       = 'Complete'
  STATUS_PROCESSING     = 'Processing'
  STATUS_UPLOADED       = 'Uploaded'
  STATUS_UPLOAD_PENDING = 'Pending'

  STATII = [
    STATUS_FAILED_IMPORT,
    STATUS_FAILED_UPLOAD,
    STATUS_IMPORTED,
    STATUS_PROCESSING,
    STATUS_UPLOADED,
    STATUS_UPLOAD_PENDING,
  ]

  def self.new_with_upload(upload)
    new(
      upload_wrapper: upload,
      status: STATUS_UPLOAD_PENDING,
      status_message: nil
    )
  end

  def oho_errors
    OhoError.for_object(self)
  end

  def clear_oho_errors
    OhoError.clear_errors(self)
  end

  def update_index_page
    broadcast_replace_to(
      "ips-payment-index",
      target: dom_id(self),
      partial: "royalties/ips/payments/payment", locals: { payment: self }
    )
  end


end
