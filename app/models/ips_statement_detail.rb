
# == Schema Information
#
# Table name: ips_statement_details
#
#  id               :bigint           not null, primary key
#  basis            :string(255)
#  basis_for_charge :decimal(10, 2)   not null
#  detail           :string(255)      not null
#  due_this_month   :decimal(10, 2)   not null
#  factor_or_rate   :decimal(6, 4)    not null
#  month_due        :date
#  section          :string(255)      not null
#  subsection       :string(255)      not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  ips_statement_id :bigint           not null
#
# Indexes
#
#  index_ips_statement_details_on_ips_statement_id  (ips_statement_id)
#
# Foreign Keys
#
#  fk_rails_...  (ips_statement_id => ips_statements.id)

class IpsStatementDetail < ActiveRecord::Base

  include ActionView::RecordIdentifier   # for dom_id

  SECTION_REVENUE = "REVENUE"
  SECTION_EXPENSE = "EXPENSE"
  SECTIONS = [SECTION_REVENUE, SECTION_EXPENSE]

  belongs_to :ips_statement, counter_cache: true
  has_many   :ips_detail_lines, dependent: :destroy

  validates :section, inclusion: { in: SECTIONS }
  validates :subsection, presence: true
  validates :detail, presence: true

  validates :basis_for_charge, numericality: true
  validates :factor_or_rate,   numericality: true
  validates :due_this_month,   numericality: true

  scope :expense, -> { where(section: SECTION_EXPENSE) }
  scope :revenue, -> { where(section: SECTION_REVENUE) }


  private

  after_save :maybe_update_status
  def maybe_update_status
    if saved_change_to_uploaded_at?
       broadcast_replace_to(
         dom_id(ips_statement, :show),
         target: dom_id(self, :status),
         partial: "royalties/ips/statements/detail_status", locals: { statement: self.ips_statement, item: self }
       )
    end
  end
end
