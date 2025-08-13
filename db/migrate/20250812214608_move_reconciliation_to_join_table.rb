class MoveReconciliationToJoinTable < ActiveRecord::Migration[8.0]
  def up
    IpsPaymentAdviceLine.transaction do
      IpsPaymentAdviceLine.all do |line|
        if line.ips_statement_detail_id.present?
          join = IpsReconciliation.new(
            ips_payment_advice_line_id: line.id,
            ips_statement_detail_id: line.ips_statement_detail_id
          )
          join.save!
          line.ips_statement_detail_id = nil
          line.save!
        end
      end
    end
  end

  def down
    IpsPaymentAdviceLine.transaction do
      IpsReconciliation.all do |recon|
        recon.ips_payment_advice_line.ips_statement_detail_id = recon.ips_statement_detail_id
        recon.ips_payment_advice_line.save!
        recon.destroy
      end
    end
  end
end
