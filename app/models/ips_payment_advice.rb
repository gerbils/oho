# == Schema Information
#
# Table name: ips_payment_advices
#
#  id                   :bigint           not null, primary key
#  discounts_taken      :boolean          default(FALSE)
#  pay_cycle            :string(255)
#  pay_cycle_seq_number :string(255)
#  payment_date         :date
#  payment_reference    :string(255)
#  status               :string(255)      default("pending"), not null
#  status_message       :string(255)
#  total_amount         :decimal(10, 2)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  upload_wrapper_id    :bigint           not null
#
# Indexes
#
#  index_ips_payment_advices_on_upload_wrapper_id  (upload_wrapper_id)
#
# Foreign Keys
#
#  fk_rails_...  (upload_wrapper_id => upload_wrappers.id)
#
class IpsPaymentAdvice < ApplicationRecord
  include ActionView::RecordIdentifier   # for dom_id

  has_many   :ips_payment_advice_lines, dependent: :destroy
  has_many   :ips_statement_details, through: :ips_payment_advice_lines
  belongs_to :import_summary, optional: true
  belongs_to :upload_wrapper, dependent: :destroy, optional: true


  validates :pay_cycle,            presence: true, on: :update
  validates :pay_cycle_seq_number, presence: true, on: :update
  validates :payment_reference,    presence: true, on: :update
  validates :payment_date,         presence: true, uniqueness: { message: "This payment advice has already been uploaded." }
  validates :total_amount,         presence: true, numericality: true, on: :update

  after_update  :update_index_page, unless: -> { Rails.env.test? }
  before_create :initialize_discounts_flag
  after_create  :add_to_index_page, unless: -> { Rails.env.test? }

  STATUS_FAILED_IMPORT  = 'Failed import'
  STATUS_FAILED_RECONCILE = 'Failed reconcile'
  STATUS_FAILED_UPLOAD  = 'Failed upload'
  STATUS_IMPORTED       = 'Imported'
  STATUS_PARTIALLY_RECONCILED  = 'Partially reconciled'
  STATUS_PROCESSING     = 'Processing'
  STATUS_RECONCILED     = 'Reconciled'
  STATUS_UPLOADED       = 'Uploaded'
  STATUS_UPLOAD_PENDING = 'Pending'

  STATII = [
    STATUS_FAILED_IMPORT,
    STATUS_FAILED_RECONCILE,
    STATUS_FAILED_UPLOAD,
    STATUS_IMPORTED,
    STATUS_PARTIALLY_RECONCILED,
    STATUS_PROCESSING,
    STATUS_RECONCILED,
    STATUS_UPLOADED,
    STATUS_UPLOAD_PENDING,
  ]

  def self.new_with_upload(upload)
    advice = new(
      upload_wrapper: upload,
      status: STATUS_UPLOAD_PENDING,
      status_message: nil
    )
    if upload.status != UploadWrapper::STATUS_PENDING
      advice.errors.add(:base, "Upload is not pending")
    else
      upload.update!(status: UploadWrapper::STATUS_PROCESSING, status_message: nil)
      Royalties::Ips::PaymentAdviceUpload.handle(advice, upload)
    end
    advice
  end

  def self.stats()
    query = %{
      SELECT count(*), sum(total_amount), status FROM ips_payment_advices  GROUP BY status
    }
    connection.execute(query).map do |(count, total, status)|
      { count:, total:, status: }
    end
  end

  def all_reconciled?
    ips_payment_advice_lines.where(ips_statement_detail_id: nil).count.zero?
  end

  def oho_errors
    OhoError.for_object(self)
  end

  def clear_oho_errors
    OhoError.clear_errors(self)
  end

  def initialize_discounts_flag
    self.discounts_taken = false if self.discounts_taken.nil?
  end

  def add_to_index_page
    broadcast_prepend_to(
      "ips-payment-index",
      target: "payment-list",
      partial: "royalties/ips/payments/payment", locals: { payment: self }
    )
  end


  def update_index_page
    broadcast_replace_to(
      "ips-payment-index",
      target: dom_id(self),
      partial: "royalties/ips/payments/payment", locals: { payment: self }
    )
  end


end
