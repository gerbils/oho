# Import the data from a given LP upload
require "pry"

module Royalties::Ips::ImportHandler

  class Totals
    def initialize
      @free_units    = 0
      @paid_units    = 0
      @return_units  = 0
      @paid_amount   = BigDecimal("0.00")
      @return_amount = BigDecimal("0.00")
    end
    attr_accessor :free_units, :paid_units, :return_units, :paid_amount, :return_amount
  end

  extend self
  extend ActiveSupport::NumberHelper

  def import(statement)
    now = Time.now

    ri_values = statement.statement_lines
    if ri_values.empty?
      raise "No royalty items found"
    end

    totals = accumulate_totals(ri_values)
    reconcile_ris_with_statement(statement, totals)

    RoyaltyItem.connection.transaction do
      RoyaltyItem.insert_all!(ri_values.map(&:to_h))
      statement.status = IpsStatement::STATUS_IMPORTED
      statement.imported_at          = now
      statement.import_free_units    = totals.free_units
      statement.import_paid_units    = totals.paid_units
      statement.import_return_units  = totals.return_units
      statement.import_paid_amount   = totals.paid_amount
      statement.import_return_amount = totals.return_amount
      statement.status_message       = nil
      statement.save!
    end
  end

  def accumulate_totals(ri_values)
    totals = Totals.new
    ri_values.each do |ri|
      totals.free_units    += ri[:free_units]
      totals.paid_units    += ri[:paid_units]
      totals.return_units  += ri[:return_units]
      totals.paid_amount   += ri[:paid_amount]
      totals.return_amount += ri[:return_amount]
    end
    totals
  end

  def reconcile_ris_with_statement(statement, totals)
    # each detail might be off, so allow for a penny on each
    unless (statement.net_client_earnings - (totals.paid_amount + totals.return_amount)).abs < 0.30
      raise(
        "Net client earnings mismatch—\n" +
        "statement: #{number_to_currency(statement.net_client_earnings)},\n" +
        "calculated: #{number_to_currency(totals.paid_amount + totals.return_amount)}")
    end
  end
end
