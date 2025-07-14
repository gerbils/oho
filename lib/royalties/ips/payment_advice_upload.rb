require 'pry'

module Royalties::Ips; end
module Royalties::Ips::PaymentAdviceUpload
  extend self
  extend Royalties::Shared


  def handle(payment, upload_wrapper)
    payment.clear_oho_errors
    file = upload_wrapper.file
    excel_file_attached?(file)
    add_details_to_upload(upload_wrapper, file)

    payment = Royalties::Ips::ParsePaymentAdvice.parse(
      payment,
      upload_wrapper.file.download,
      'xlsx')
    payment.status =
      if payment.valid?
        IpsPaymentAdvice::STATUS_UPLOADED
      else
        IpsPaymentAdvice::STATUS_FAILED_UPLOAD
      end

    payment
  end
end
