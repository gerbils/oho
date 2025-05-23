class Creators::AuthorCalendarItemsController < Creators::CreatorsBaseController
  before_action :set_author_calendar_item, only: %i[ show edit update destroy ]
  before_action :partition_old_new, only: %i[ index delete_old ]

  # GET /author_calendar_items or /author_calendar_items.json
  def index
  end

  # GET /author_calendar_items/1 or /author_calendar_items/1.json
  def show
  end

  # GET /author_calendar_items/new
  def new
    @author_calendar_item = Current.user.author_calendar_items.new
  end

  # GET /author_calendar_items/1/edit
  def edit
  end

  # POST /author_calendar_items or /author_calendar_items.json
  def create
    @author_calendar_item = AuthorCalendarItem.new(author_calendar_item_params)

    respond_to do |format|
      @author_calendar_item.user = Current.user
      if @author_calendar_item.save
        format.html { redirect_to creators_author_calendar_item_url(@author_calendar_item), notice: "Author calendar item was successfully created." }
        format.json { render :show, status: :created, location: @author_calendar_item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @author_calendar_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /author_calendar_items/1 or /author_calendar_items/1.json
  def update
    respond_to do |format|
      if @author_calendar_item.update(author_calendar_item_params)
        format.html { redirect_to creators_author_calendar_item_url(@author_calendar_item), notice: "Author calendar item was successfully updated." }
        format.json { render :show, status: :ok, location: @author_calendar_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @author_calendar_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /author_calendar_items/1 or /author_calendar_items/1.json
  def destroy
    @author_calendar_item.destroy!

    respond_to do |format|
      format.html { redirect_to creators_author_calendar_items_url, notice: "Author calendar item was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  def delete_old
    index()
    # one by one so we invoke the callbacks`
    @past_acis.each do |paci|
      paci.destroy!
    end
    redirect_to action: :index
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_author_calendar_item
      @author_calendar_item = AuthorCalendarItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def author_calendar_item_params
      params.require(:author_calendar_item).permit(:start_date, :what, :where, :event_url)
    end

  def partition_old_new
    acis = Current.user.author_calendar_items.order("start_date desc")
    yesterday = 1.day.ago
    @past_acis, @current_acis = acis.partition { |aci| aci.start_date < yesterday }
  end
end
