# == Schema Information
#
# Table name: lp_statements
#
#  id                :bigint           not null, primary key
#  date_on_report    :date
#  imported_at       :datetime
#  report_period     :string(255)
#  statement_total   :decimal(10, 2)   default(0.0)
#  status            :string(255)
#  status_message    :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  upload_wrapper_id :bigint           not null
#
# Indexes
#
#  index_lp_statements_on_upload_wrapper_id  (upload_wrapper_id)
#
# Foreign Keys
#
#  fk_rails_...  (upload_wrapper_id => upload_wrappers.id)
#
class LpStatement < ApplicationRecord

  STATUS_PENDING        = 'pending'
  STATUS_FAILED_IMPORT  = 'failed import'
  STATUS_FAILED_UPLOAD  = 'failed upload'
  STATUS_IMPORTED       = 'imported'
  STATUS_INCOMPLETE     = 'incomplete'
  STATUS_UPLOAD_PENDING = 'upload pending'
  STATUS_PROCESSING     = 'processing'
  STATUS_UPLOADED       = 'uploaded'

  STATII = [
    STATUS_UPLOAD_PENDING, STATUS_INCOMPLETE, STATUS_PROCESSING, STATUS_UPLOADED,
    STATUS_IMPORTED, STATUS_FAILED_UPLOAD, STATUS_FAILED_IMPORT
  ]

  belongs_to :upload_wrapper, dependent: :destroy
  has_many   :lp_statement_lines, dependent: :destroy

  validates :status,         inclusion: { in: STATII }

  after_initialize :set_initial_status

  # broadcasts_refreshes

  def self.new_with_upload(upload)
    statement = new(
      upload_wrapper: upload,
      status: STATUS_UPLOAD_PENDING,
      status_message: nil
    )
    statement
  end

  def self.stats()
    query = %{
      SELECT count(*), sum(statement_total), status FROM lp_statements  GROUP BY status
    }
    connection.execute(query).map do |(count, total, status)|
      { count:, total:, status: }
    end
  end


  private

  # Sets the initial status to pending if not already set
  def set_initial_status
    self.status ||= STATUS_PENDING
  end

  def set_uploaded_at
    self.uploaded_at = Time.current
  end
end
