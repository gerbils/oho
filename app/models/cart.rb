class Cart < Order

  def place_sendowl_order(asof, created, updated)
    self.type        = "PlacedOrder"
    self.when_billed = DateTime.parse(asof.to_s)
    self.created_at = DateTime.parse(created.to_s)
    self.updated_at = DateTime.parse(updated.to_s)
    if !valid?
      pp discount_items.first
      pp errors.messages
      exit
    else
    save!
    end
  end

end
