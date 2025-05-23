class AuthorCalendarItem < LegacyRecord
  belongs_to :user

  validates_presence_of :user_id, :what, :start_date, :where
  before_save :normalize_url
  after_save  :update_online_store
  after_destroy :remove_from_online_store

  private

  def update_online_store
#    Shopify::UpdateAuthorCalendarJob.perform_async(self.id)
  end

  def remove_from_online_store
#    Shopify::RemoveAuthorCalendarJob.perform_async(self.id)
  end

  def normalize_url
    unless event_url.blank?
      if event_url !~ %r{^https?://}
        self.event_url = event_url.sub(%r{^.*://}, '')
        self.event_url = "http://#{event_url}"
      end
    end
  end

end
