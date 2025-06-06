# == Schema Information
#
# Table name: author_royalty_payments
#
#  id                    :integer          not null, primary key
#  amount_in_cents       :integer
#  destination           :string(255)
#  old_amount            :decimal(10, 2)   not null
#  old_check_number      :string(64)       not null
#  paid_on               :date             not null
#  transaction_ident     :string(40)
#  created_at            :datetime
#  updated_at            :datetime
#  payout_recipient_id   :integer
#  payout_transaction_id :integer
#  user_id               :integer          not null
#
# Indexes
#
#  fk_author_royalty_payments_user_id  (user_id)
#
# Foreign Keys
#
#  fk_author_royalty_payments_user_id  (user_id => users.id)
#
class AuthorRoyaltyPayment < LegacyRecord
  belongs_to :user

  scope :actual_payments, -> {
    joins("LEFT OUTER JOIN payout_transactions ON payout_transactions.id = author_royalty_payments.payout_transaction_id").
    where("amount_in_cents > ?" , 1).
    where("(author_royalty_payments.payout_transaction_id IS NULL OR payout_transactions.status = ?)" , PayoutTransaction::STATUS_COMPLETED)
  }

  def amount
    BigDecimal(self.amount_in_cents,2)/BigDecimal("100.00",2)
  end


end
