class Test < ActiveRecord::Base
  after_update_commit :update_index_page

  def update_index_page
    broadcast_replace_to(
      "test-index",
      target: "test_#{self.id}",
      partial: "test/counter", locals: { count: self }
    )
  end

end
