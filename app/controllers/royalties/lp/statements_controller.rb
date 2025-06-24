class Royalties::Lp::StatementsController < ApplicationController
  before_action :set_statement, only: %i[ show destroy import ]

  def index
    @upload_wrapper ||= UploadWrapper.new
    @pagy, @statements = pagy(LpStatement.order(created_at: :desc), limit: 5)
  end

  def show
  end


  def create
    @upload_wrapper = UploadWrapper.create!(upload_params)
    @statement = LpStatement.new_with_upload(@upload_wrapper)
    @statement.save!    # we need this to attach errors to

    Lp::UploadRoyaltyJob.new.perform(@statement.id, @upload_wrapper.id)
    respond_to do |format|
        format.html { redirect_to royalties_lp_statements_url, notice: "Upload initiated" }
    end
  end

  def import
    Lp::ImportRoyaltyJob.new.perform(@statement.id)

    respond_to do |format|
      format.html { redirect_to royalties_lp_statements_url, notice: "Import to PIP initiated" }
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
    @statement.destroy!

    respond_to do |format|
      format.html { redirect_to royalties_lp_statement_url, status: :see_other, notice: "Upload was successfully destroyed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_statement
      @statement = LpStatement.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def upload_params
      params.expect(upload_wrapper: [ :file ])
    end
end
