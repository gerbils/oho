class OhoError < ActiveRecord::Base
      # t.string  :owner_dom_id
      # t.string  :display_tag, null: false
      # t.integer :level,       null: false, default: 0
      # t.string  :label,       null: false
      # t.string  :message,     limit: 2048

  after_create_commit  :notify_create
  after_update_commit  :notify_update
  after_destroy_commit :notify_destroy

  def owner=(object)
    self.owner_dom_id = OhoError.error_id(object)
  end

  def self.clear_errors(object)
    where(owner_dom_id: error_id(object)).delete_all
  end

  def self.for_object(object)
    where(owner_dom_id: error_id(object))
  end

  def notify_update
       broadcast_replace_to(
         owner_dom_id,
         target: dom_id(self),
         partial: "shared/oho_error", locals: { error: self }
       )
  end

  def notify_destroy
       broadcast_remove_to(owner_dom_id, target: dom_id(self))
  end

  # def owner_class
  #   owner_dom_id.split("-")[2]
  # end
  # def owner_class_object
  #   owner_class.constantize
  # rescue NameError
  #   fail "Invalid class name: #{owner_class.inspect} in error message ##{id}"
  # end
  #
  private

  def self.error_id(object)
     "errors_#{object.class.name.underscore}_#{object.id}"
  end

  def notify_create
       broadcast_append_to(
         owner_dom_id,
         target: "oho-errors",
         partial: "shared/oho_error", locals: { error: self }
       )
  end
end
