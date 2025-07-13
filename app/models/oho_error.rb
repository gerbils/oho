# == Schema Information
#
# Table name: oho_errors
#
#  id           :bigint           not null, primary key
#  display_tag  :string(255)
#  label        :string(255)      not null
#  level        :integer          default(0), not null
#  message      :string(2048)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  owner_dom_id :string(255)      not null
#
# Indexes
#
#  index_oho_errors_on_owner_dom_id  (owner_dom_id)
#
class OhoError < ActiveRecord::Base
  include ActionView::RecordIdentifier   # for dom_id

  SUCCESS = 0
  INFO    = 1
  WARNING = 2
  ERROR   = 3

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
