class CoverImage < Image

  belongs_to :master,
    :class_name => 'CoverImage',
    :foreign_key => 'images_id',
    optional: true

  has_many   :variants,
    :class_name => 'CoverImage',
    :foreign_key => 'images_id'

  def self.find_for_file_name(file_name)
    name = File.basename(file_name, ".*")
    self.find_by_product_code_and_variant(name)
  end

  def self.find_by_product_code_and_variant(name)
    self.where(product_code_and_variant: name).first
  end

  def self.product_code(name)
    case name
    when /(.+)-beta$/
      $1.dup
    else
      name
    end
  end

  def self.from_file(file_name)
    name = File.basename(file_name, ".*")
    code = product_code(name)
    new(file_name: file_name, product_code: code, product_code_and_variant: name)
  end

  def self.create_or_fetch(width:, height:, name:)
    cav = self.where(name:).first
    cav || self.new(name:, width:, height:)
  end


  def variant_suffix
    base_len = self.product_code.length
    var_len  = self.product_code_and_variant.length
    if base_len >= var_len
      nil
    else
      self.product_code_and_variant[base_len..-1]
    end
  end
end
