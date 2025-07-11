class Royalties::Ips::PaymentsController < ApplicationController
  # before_action :set_statement, only: %i[ show destroy import upload_revenue_lines ]

  def index
    @upload_wrapper ||= UploadWrapper.new
    @pagy, @payments = pagy(IpsPaymentAdvice.order(created_at: :desc), limit: 12)
  end

  def show
    @payment = IpsPaymentAdvice.find(params[:id])
  end

  def create
    @upload_wrapper = UploadWrapper.create!(single_upload_params)
    @payment = IpsPaymentAdvice.new_with_upload(@upload_wrapper)
    @payment.save!    # we need this to attach errors to

    Ips::UploadPaymentJob.perform_later(@payment.id, @upload_wrapper.id)
    respond_to do |format|
        format.html {  redirect_to royalties_ips_payments_path }
    end
  end

  private

  def single_upload_params
    params.expect(upload_wrapper: [ :file ])
  end

end

