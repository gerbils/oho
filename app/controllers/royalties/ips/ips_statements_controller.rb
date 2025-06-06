require 'pry'

class Royalties::Ips::IpsStatementsController < ApplicationController
  before_action :set_statement, only: %i[ show destroy upload_revenue_lines ]


  def index
    @upload_wrapper ||= UploadWrapper.new
    @pagy, @statements = pagy(IpsStatement.order(created_at: :desc), limit: 5)
  end

  def show
    @upload_wrapper ||= UploadWrapper.new
  end

  def create
    @upload_wrapper = UploadWrapper.new(upload_params)
    respond_to do |format|
      if @upload_wrapper.save
        Ips::UploadRoyaltyJob.new.perform(@upload_wrapper.id)
        @upload_wrapper.reload  # to get the status after job runs
        if @upload_wrapper.status == UploadWrapper::STATUS_FAILED_UPLOAD
          index
          format.html { redirect_to action: "index", status: :unprocessable_entity }
        else
          format.html {  redirect_to royalties_ips_ips_statement_path(@upload_wrapper.id_of_created_object), notice: "Now upload the details spreadsheets…"  }
        end
      else
        index
        fail @upload_wrapper.inspect
        format.html { render :index, status: :unprocessable_entity, error: @upload_wrapper.errors.full_messages.to_sentence }
      end
    end
  end

  def upload_revenue_lines
    @upload_wrapper = UploadWrapper.new(upload_params)

    respond_to do |format|
      if @upload_wrapper.save
        Ips::UploadRevenueLinesJob.new.perform(@upload_wrapper.id)
        if @upload_wrapper.status == UploadWrapper::STATUS_FAILED_UPLOAD
          index
          format.html { redirect_to action: "index", status: :unprocessable_entity }
        else
          format.html {  redirect_to royalties_ips_ips_statement_path(@statement), notice: "Details uploaded"  }
        end
      else
        index
        fail @upload_wrapper.inspect
        format.html { render :index, status: :unprocessable_entity, error: @upload_wrapper.errors.full_messages.to_sentence }
      end
    end

  end

  def import
    @upload = Upload.find(params[:id])
    Ips::ImportRoyaltyJob.new.perform(@upload.id)

    respond_to do |format|
      format.html { redirect_to royalties_ips_uploads_url, notice: "Import to PIP initiated" }
    end
  end

  def destroy
    @statement.destroy!

    respond_to do |format|
      format.html { redirect_to royalties_ips_ips_statements_url, status: :see_other, notice: "Statement deleted" }
    end
  end

  private
    def set_statement
      @statement = IpsStatement.find(params.expect(:id))
    end

    def upload_params
      params.expect(upload_wrapper: [ :file ])
    end
end
