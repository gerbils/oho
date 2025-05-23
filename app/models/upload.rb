class Upload < ApplicationRecord
  STATUS_PENDING       = 'pending'
  STATUS_PROCESSING    = 'processing'
  STATUS_UPLOADED      = 'uploaded'
  STATUS_IMPORTED      = 'imported'
  STATUS_FAILED_UPLOAD = 'failed upload'
  STATUS_FAILED_IMPORT = 'failed mport'
  STATII = [ STATUS_PENDING, STATUS_PROCESSING, STATUS_UPLOADED, STATUS_IMPORTED,
             STATUS_FAILED_UPLOAD, STATUS_FAILED_IMPORT ]

  CHANNEL_LP         = 'ORA LP'
  CHANNEL_IPS        = 'Ingram IPS'
  CHANNEL_ORA_LEGACY = 'ORA Legacy'
  CHANNELS = [ CHANNEL_LP, CHANNEL_IPS, CHANNEL_ORA_LEGACY ]

  has_one_attached :uploaded_file

  has_many :royalty_raw_lp_data, dependent: :destroy

  validates :upload_channel, presence: true, inclusion: { in: CHANNELS }
  validates :uploaded_file,  presence: true
  validates :status,         inclusion: { in: STATII }

  before_create    :set_uploaded_at
  after_initialize :set_initial_status

  broadcasts_refreshes

  private

  def set_initial_status
    self.status ||= STATUS_PENDING
  end

  def set_uploaded_at
    self.uploaded_at = Time.current
  end
end
