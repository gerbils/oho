class Creators::BuildStatusesController < Creators::CreatorsBaseController

  def index
    @build_statuses = BuildStatus.all_with_sku()
  end

  def pdf
    build_status = BuildStatus.find(params[:id])
    redirect_to build_status.pdf_url, allow_other_host: true
  end

  def log
    @build_status = BuildStatus.find(params[:id])
    @log_text = @build_status.log_text
    respond_to do |format|
      format.html { redirect_to build_statuses_url }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("log_#{@build_status.id}", partial: 'build_statuses/log'),
          turbo_stream.replace("toggle_log_#{@build_status.id}", partial: 'build_statuses/hide_log_button'),
        ]
      end
    end
  end

  def hide_log
    @build_status = BuildStatus.find(params[:id])
    respond_to do |format|
      format.html { redirect_to build_statuses_url }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("log_#{@build_status.id}"),
          turbo_stream.replace("toggle_log_#{@build_status.id}", partial: 'build_statuses/view_log_button'),
        ]
      end
    end
  end

end
