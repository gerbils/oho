class Royalties::Ips::PaymentsController < ApplicationController
  # before_action :set_statement, only: %i[ show destroy import upload_revenue_lines ]

  def index
    @upload_wrapper ||= UploadWrapper.new
    @pagy, @payments = pagy(IpsPaymentAdvice.order(created_at: :desc), limit: 12)
  end

  def show
    @payment = IpsPaymentAdvice.find(params[:id])
    @revenues_and_expenses = @payment.revenues_and_expenses
    @focus_line = params[:focus_line]&.to_i
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

  # shows the unreconciled statement details for a month, so the user can pick
  # the ones that make up a payment advice line
  def match_line
    load_match_candidates
  end

  def apply_match
    detail_ids = Array(params[:detail_ids])
    details = IpsStatementDetail.where(id: detail_ids).to_a
    load_match_candidates

    if details.length != detail_ids.uniq.length
      @error = "Some of the selected transactions no longer exist"
    else
      begin
        Royalties::Ips::ReconcilePayments.reconcile_with_details(@line, details)
      rescue Royalties::Ips::ReconcilePayments::ManualReconcileError => e
        @error = e.message
      end
    end

    if @error
      @selected_ids = detail_ids.map(&:to_i)
      render :match_line, status: :unprocessable_entity
    else
      @payment.reload
      render turbo_stream: [
        turbo_stream.replace(helpers.dom_id(@line), partial: "payment_advice_line",
          locals: { line: @line.reload, discounts_taken: @payment.discounts_taken, focus_line: @line.id }),
        turbo_stream.replace("next-steps", partial: "next_steps", locals: { payment: @payment }),
        turbo_stream.update("modal", ""),
      ]
    end
  end

  def import
    @payment = IpsPaymentAdvice.find(params[:id])
    Royalties::Ips::Import.build_royalties_from_details(@payment)
    redirect_to action: :show, id: @payment.id
  end

  def destroy
    @payment = IpsPaymentAdvice.find(params[:id])
    @payment.destroy!

    respond_to do |format|
      format.html { redirect_to royalties_ips_payment_url, status: :see_other, notice: "Payment was successfully destroyed." }
    end
  end

  private

  def load_match_candidates
    @payment = IpsPaymentAdvice.find(params[:id])
    @line    = @payment.ips_payment_advice_lines.find(params[:line_id])
    @month   = params[:month].present? ? Date.parse(params[:month]) : @line.invoice_date
    @details = IpsStatementDetail.unreconciled_for_month(@month).includes(:ips_statement)
    @earlier_month = IpsStatement.where(month_ending: ...@month.beginning_of_month).maximum(:month_ending)
    @later_month   = IpsStatement.where("month_ending > ?", @month.end_of_month).minimum(:month_ending)
    @selected_ids  = []
  end

  def single_upload_params
    params.expect(upload_wrapper: [ :file ])
  end

end

