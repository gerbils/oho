class OrderComment < LegacyRecord
  belongs_to :user, optional: true
  belongs_to :order
  
  def posted_by_name
    if self.user
      self.user.name
    else
      "anon"
    end
  end
end

