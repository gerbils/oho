# == Schema Information
#
# Table name: uploads
#
#  id              :bigint           not null, primary key
#  date_on_report  :datetime
#  report_period   :string(255)
#  statement_total :decimal(10, 2)   default(0.0)
#  status          :string(255)      not null
#  imported_at     :datetime
#
# Indexes
#
#  index_uploads_on_date_on_report  (date_on_report) UNIQUE
#
class LpStatement < ApplicationRecord

  STATUS_FAILED_IMPORT = 'failed import'
  STATUS_FAILED_UPLOAD = 'failed upload'
  STATUS_IMPORTED      = 'imported'
  STATUS_INCOMPLETE    = 'incomplete'
  STATUS_PENDING       = 'pending'
  STATUS_PROCESSING    = 'processing'
  STATUS_UPLOADED      = 'uploaded'

  STATII = [
    STATUS_PENDING, STATUS_INCOMPLETE, STATUS_PROCESSING, STATUS_UPLOADED,
    STATUS_IMPORTED, STATUS_FAILED_UPLOAD, STATUS_FAILED_IMPORT
  ]

  belongs_to :upload_wrapper, dependent: :destroy
  has_many   :lp_statement_lines, dependent: :destroy

  validates :status,         inclusion: { in: STATII }

  after_initialize :set_initial_status

  # broadcasts_refreshes

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
