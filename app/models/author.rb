# == Schema Information
#
# Table name: authors
#
#  id                           :integer          not null, primary key
#  check_made_out_to            :string(255)
#  company_name                 :string(255)
#  dwolla_consent_to_migrate    :boolean
#  dwolla_founding_source_name  :string(255)
#  dwolla_id_email              :string(255)
#  dwolla_migrated              :boolean
#  first_name                   :string(255)
#  last_name                    :string(255)
#  middle_initials              :string(4)
#  needs_1099                   :boolean
#  payment_destination_verified :boolean
#  paypal_id_email              :string(255)
#  provider_code                :string(20)
#  rest_of_address              :text(16777215)
#  salutation                   :string(10)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  dwolla_account_id            :string(255)
#  dwolla_founding_source_id    :string(255)
#  dwolla_id                    :string(255)
#  encrypted_tax_id             :string(255)
#  old_encrypted_tax_id         :string(255)
#  user_id                      :integer
#
# Indexes
#
#  fk_authors_user_id  (user_id)
#
# Foreign Keys
#
#  fk_authors_user_id  (user_id => users.id)
#
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
