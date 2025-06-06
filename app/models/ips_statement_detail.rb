
# == Schema Information
#
# Table name: raw_ips_statement_details
#
#  id                   :bigint           not null, primary key
#  basis                :string(255)
#  basis_for_charge     :decimal(10, 2)   not null
#  detail               :string(255)      not null
#  due_this_month       :decimal(10, 2)   not null
#  factor_or_rate       :decimal(6, 4)    not null
#  month_due            :date
#  section              :string(255)      not null
#  subsection           :string(255)      not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  raw_ips_statement_id :bigint           not null
#
# Indexes
#
#  index_raw_ips_statement_details_on_raw_ips_statement_id  (raw_ips_statement_id)
#
# Foreign Keys
#
#  fk_rails_...  (raw_ips_statement_id => raw_ips_statements.id)
#
class IpsStatementDetail < ActiveRecord::Base

  SECTION_REVENUE = "REVENUE"
  SECTION_EXPENSE = "EXPENSE"
  SECTIONS = [SECTION_REVENUE, SECTION_EXPENSE]

  belongs_to :ips_statement
  # has_many   :raw_ips_revenue_lines, dependent: :destroy

  validates :section, inclusion: { in: SECTIONS }
  validates :subsection, presence: true
  validates :detail, presence: true

  validates :basis_for_charge, numericality: true
  validates :factor_or_rate,   numericality: true
  validates :due_this_month,   numericality: true

  scope :expense, -> { where(section: SECTION_EXPENSE) }
  scope :revenue, -> { where(section: SECTION_REVENUE) }
end
