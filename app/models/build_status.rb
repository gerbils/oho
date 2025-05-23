class BuildStatus < LegacyRecord
  STATUSES = %w(started updating building uploading succeeded failed)

  CONFIG = Rails.application.credentials[:s3_authors] || fail("no credentials fopr s3_authors in build_status model")

  ENV["AWS_ACCESS_KEY_ID"] =  CONFIG[:aws_access_key]
  ENV["AWS_SECRET_ACCESS_KEY"] =  CONFIG[:aws_secret_access_key]

  belongs_to :sku
  validates_inclusion_of :status, :in => STATUSES

  serialize :counts, coder: JSON

  class << self
    def for(sku)
      find_or_initialize_by_sku_id(sku.id)
    end

    def can_be_viewed_by?(user)
      user ? (user.author? || user.editor? || user.admin?) : false
    end

    def expire_old
      delete_all(['updated_at < ?', 30.days.ago])
    end

    def all_with_sku
      sql = %{
      select build_statuses.*, skus.sku as sku_sku, products.title as product_title, products.code as products_code
      from build_statuses
      join skus on skus.id = build_statuses.sku_id
      join products on products.id = skus.product_id
      order by build_statuses.updated_at DESC
      }
      find_by_sql(sql)
    end

    def s3
      @s3 ||= Aws::S3::Client.new(region: CONFIG[:aws_region])
    end
  end

  def succeeded?
    status == "succeeded"
  end

  def failed?
    status == "failed"
  end

  def in_progress?
    !succeeded? && !failed?
  end

  def pdf_key
    "#{s3_directory}/#{title_code}.pdf"
  end

  def pdf_url
    resource = Aws::S3::Resource.new(client: self.class.s3)
    bucket = resource.bucket(CONFIG[:aws_bucket])
    obj = bucket.object(pdf_key)
    obj.presigned_url(:get)

    # o = self.class.s3.get_object(bucket: CONFIG[:aws_bucket], key: pdf_key)
    # o.data.presigned_url(:get, expires_in: 60 * 60) # 1 hour
  end

  def log_key
    "#{s3_directory}/build.log"
  end

  def log_text
    o = self.class.s3.get_object(bucket: CONFIG[:aws_bucket], key: log_key)
    o.data.body.read
  end

  def title_code
    sku.product.code
  end

  def s3_directory
    "build_statuses/#{title_code}"
  end

end

