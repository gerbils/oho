class OtherImage < Image

  belongs_to :master,
    :class_name => 'OtherImage',
    :foreign_key => 'images_id',
    optional: true

  has_many   :variants,
    :class_name => 'OtherImage',
    :foreign_key => 'images_id'

  def variant_name(suffix)
    self.file_name.sub(/\.(\w+)$/, "#{suffix}.\\1")
  end
end
