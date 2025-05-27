class Royalties::Lp::UploadsController < ApplicationController
  before_action :set_upload, only: %i[ show destroy ]

  # GET /uploads or /uploads.json
  def index
    @pagy, @uploads = pagy(Upload.all.order(uploaded_at: :desc), limit: 5)
  end

  # GET /uploads/1 or /uploads/1.json
  def show
  end

  # GET /uploads/new
  def new
    @upload = Upload.new
  end

  # # GET /uploads/1/edit
  # def edit
  # end

  # POST /uploads or /uploads.json
  def create
    @upload = Upload.new(upload_params)

    respond_to do |format|
      if @upload.save
        # Lp::UploadRoyaltyJob.perform_later(@upload.id)
        Lp::UploadRoyaltyJob.perform(@upload.id)
        format.html { redirect_to royalties_lp_uploads_url, notice: "Upload initiated" }
        format.json { render :show, status: :created, location: @upload }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  def import
    @upload = Upload.find(params[:id])
    Lp::ImportRoyaltyJob.perform_later(@upload.id)

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
    def set_upload
      @upload = Upload.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def upload_params
      params.expect(upload: [ :upload_channel, :uploaded_at, :description, :imported_at, :uploaded_file ])
    end
end
