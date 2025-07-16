# == Schema Information
#
# Table name: import_summaries
#
#  id              :bigint           not null, primary key
#  import_amount   :decimal(10, 2)
#  import_class    :string(255)
#  imported_at     :datetime
#  notes           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  import_class_id :integer
#
class ImportSummary < ApplicationRecord

  def corresponding_import
    klass = self.import_class.constantize
    klass.find_by(id: self.import_class_id)
  end
end
