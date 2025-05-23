module RoyaltiesHelper

  def payment_reference_number(payment)
    provider =  field_or_default(payment.destination, "Check")
    provider = "Dwolla" if provider.start_with?('http')
    ident    =  field_or_default(payment.transaction_ident, "unknown")

    "#{provider} ##{ident}"
  end

private

  def field_or_default(field, default)
    field.blank? ? default : field
  end
end
