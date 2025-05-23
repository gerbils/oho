class DownloadedImage

  attr_reader :body, :content_type

  def initialize(s3_download)
    @body = s3_download[:body]
    @content_type = s3_download[:content_type]
  end
end
