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

    respond_to do |format|
      if @payment.save
        format.html { redirect_to royalties_ips_payments_path }
      else
        format.html { redirect_to royalties_ips_payments_path, alert: "Upload failed: #{@payment.errors.full_messages.join("<br/>")}" }
      end
    end
  end

  def reconcile
    @payment = IpsPaymentAdvice.find(params[:id])
    Ips::ReconcilePaymentJob.perform_later(@payment.id)
  end


  def destroy
    @payment = IpsPaymentAdvice.find(params[:id])
    @payment.destroy!

    respond_to do |format|
      format.html { redirect_to royalties_ips_payment_url, status: :see_other, notice: "Payment was successfully destroyed." }
    end
  end

  private

  def single_upload_params
    params.expect(upload_wrapper: [ :file ])
  end

end

