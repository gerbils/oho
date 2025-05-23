class LegacyRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { reading: :legacy, writing: :legacy } 

end
