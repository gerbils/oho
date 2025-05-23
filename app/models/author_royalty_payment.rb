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
