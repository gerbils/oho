require 'pry'

class Royalties::Ips::StatementsController < ApplicationController
  before_action :set_statement, only: %i[ show destroy upload_revenue_lines ]

  def xxx
    # @statement = IpsStatement.find(params.expect(:id))
    # @detail =  @statement.details.find(357)
    # if @detail.uploaded_at.present?
    #   @detail.uploaded_at = nil
    # else
    #   @detail.uploaded_at = Time.current
    # end
    # @detail.save
    # e = OhoError.new(owner: @statement, level: 1, label: "Test", display_tag: "unused", message: "Test message")
    # e.save
    s = IpsStatement.find(16)
    s.imported_at = Time.now
    s.save!
    render html: "OK"

  end

  def index
    @upload_wrapper ||= UploadWrapper.new
    @pagy, @statements = pagy(IpsStatement.order(created_at: :desc), limit: 5)
  end

  def show
    @upload_files ||= UploadFiles.new
  end

  def create
    @upload_wrapper = UploadWrapper.create!(single_upload_params)
    @statement = IpsStatement.new_with_upload(@upload_wrapper)
    @statement.save!    # we need this to attach errors to

    Ips::UploadRoyaltyJob.perform_later(@statement.id, @upload_wrapper.id)
    respond_to do |format|
        format.html {  redirect_to royalties_ips_statements_path, notice: "Now upload the details spreadsheets…"  }
    end
  end

  def upload_revenue_lines
    @upload_files = UploadFiles.new(files: params.dig(:upload_files, :files))

    @upload_files.files.each do |file|
      next if file.blank?    # no idea why thwe first entry is an empty string...
      upload_wrapper = UploadWrapper.create!(file: file, ips_statement: @statement)
      Ips::UploadDetailLinesJob.perform_later(@statement.id, upload_wrapper.id)
    end

    respond_to do |format|
      format.html {  redirect_to royalties_ips_statement_path(@statement), notice: @statement.status } #"Details uploaded"  }
    end
  end

  def detail
    @statement = IpsStatement.find(params.expect(:id))
    @detail = @statement.details.find(params.expect(:revenue_line_id))
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
      format.html { redirect_to royalties_ips_statements_url, status: :see_other, notice: "Statement deleted" }
    end
  end

  private
    def set_statement
      @statement = IpsStatement.find(params.expect(:id))
    end

    def single_upload_params
      params.expect(upload_wrapper: [ :file ])
    end

    def plural_upload_params
      params.expect(upload_files: [ :files ])
    end
end
