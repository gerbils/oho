class Author < LegacyRecord
  belongs_to :user

  def name
    [salutation, first_name, middle_initials, last_name].compact.reject(&:empty?).join(' ')
  end

  def tax_id
    return nil unless self.encrypted_tax_id
    SimpleCodec.decrypt(self.encrypted_tax_id)
  end
end
