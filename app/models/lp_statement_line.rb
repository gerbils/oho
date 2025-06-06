# == Schema Information
#
# Table name: lp_statement_lines
#
#  id                :bigint           not null, primary key
#  author            :string(255)
#  commission_earned :decimal(10, 2)   default(0.0), not null
#  commission_rate   :decimal(5, 4)    default(0.0), not null
#  e_isbn            :string(255)
#  isbn              :string(255)
#  publisher         :string(255)
#  sales             :decimal(10, 2)   default(0.0), not null
#  title             :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  lp_statement_id   :bigint           not null
#  sku_id            :integer
#
# Indexes
#
#  index_lp_statement_lines_on_lp_statement_id  (lp_statement_id)
#
# Foreign Keys
#
#  fk_rails_...  (lp_statement_id => lp_statements.id)
#
class LpStatementLine < ActiveRecord::Base

  belongs_to :sku

  validates :sku,               presence: true
  validates :isbn,              presence: true
  validates :title,             presence: true
  validates :publisher,         presence: true
  validates :author,            presence: true
  validates :sales,             presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_rate,   presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_earned, presence: true, numericality: { greater_than_or_equal_to: 0 }

end
