FactoryBot.define do

  factory :ips_statement_detail do
    association      :ips_statement
    association      :upload_wrapper
    section          { IpsStatementDetail::SECTION_EXPENSE }
    subsection       { "subsection" }
    detail           { "detail" }
    month_due        { Date.new(2025, 4, 1) }
    basis_for_charge { 0 }
    factor_or_rate   { 0 }
    due_this_month   { 0 }
    after(:build) do |detail|
      # Ensure the associated ips_statement has an upload_wrapper
      detail.ips_statement.upload_wrapper = create(:upload_wrapper)
      detail.ips_statement.upload_wrapper.save!
    end
  end
end
