FactoryBot.define do

  factory :ips_statement_detail do
    association      :ips_statement
    section          { IpsStatementDetail::SECTION_EXPENSE }
    subsection       { "subsection" }
    detail           { "detail" }
    month_due        { Date.new(2025, 4, 1) }
    basis_for_charge { 0 }
    factor_or_rate   { 0 }
    due_this_month   { 0 }
  end
end
