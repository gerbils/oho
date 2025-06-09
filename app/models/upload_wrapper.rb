# == Schema Information
#
# Table name: upload_wrappers
#
#  id                   :bigint           not null, primary key
#  filename             :string(255)
#  id_of_created_object :integer
#  mime_type            :string(255)
#  size                 :integer
#  status               :string(255)
#  status_message       :text(65535)
#  uploaded_at          :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class UploadWrapper < ApplicationRecord
  has_one_attached :file
  has_one :ips_statement

  # this is a hack. At the point we upload and process these lines, we don't know which ips detail
  # they belong to, but we have to return them via the database because they might be processed by a
  # job. We attached them temporrily to the upload, and then reattache them to the correct detail
  has_many :ips_revenue_lines

  STATUS_FAILED_IMPORT = 'failed mport'
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

  # validates :status,        inclusion: { in: STATII }  TODO: need to split upload and statement
  # status
  validates :file,          presence: true

  after_initialize :set_initial_status
  before_create    :set_metadata_from_file

  private

  # Sets the initial status to pending if not already set
  def set_initial_status
    self.status ||= STATUS_PENDING
  end

  def set_metadata_from_file
    if file.attached?
      self.filename = file.filename.to_s
      self.mime_type = file.content_type
      self.size = file.byte_size
      self.uploaded_at = Time.current
    else
      errors.add(:file, "must be attached")
    end
  rescue => e
    errors.add(:base, "Error setting metadata from file: #{e.message}")
  end
end
