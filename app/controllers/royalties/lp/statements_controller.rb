class Royalties::Lp::StatementsController < ApplicationController
  before_action :set_statement, only: %i[ show destroy ]

  def index
    @upload_wrapper ||= UploadWrapper.new
    @pagy, @statements = pagy(LpStatement.order(created_at: :desc), limit: 5)
  end

  def show
  end


  def create
    @upload = UploadWrapper.new(upload_params)

    respond_to do |format|
      if @upload.save
        # Lp::UploadRoyaltyJob.perform_later(@upload.id)
        Lp::UploadRoyaltyJob.new.perform(@upload.id)
        format.html { redirect_to royalties_lp_statements_url, notice: "Upload initiated" }
        format.json { render :show, status: :created, location: @upload }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  def import
    @upload = Upload.find(params[:id])
    Lp::ImportRoyaltyJob.new.perform(@upload.id)

    respond_to do |format|
      format.html { redirect_to royalties_lp_uploads_url, notice: "Import to PIP initiated" }
      format.json { render :show, status: :ok, location: @upload }
    end
  end

  # PATCH/PUT /uploads/1 or /uploads/1.json
  # def update
  #   respond_to do |format|
  #     if @upload.update(upload_params)
  #       format.html { redirect_to @upload, notice: "Upload was successfully updated." }
  #       format.json { render :show, status: :ok, location: @upload }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @upload.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /uploads/1 or /uploads/1.json
  def destroy
    @upload.destroy!

    respond_to do |format|
      format.html { redirect_to royalties_lp_uploads_url, status: :see_other, notice: "Upload was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_statement
      @statement = Statement.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def upload_params
      params.expect(upload_wrapper: [ :file ])
    end
end
