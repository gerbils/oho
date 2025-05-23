class Image < ApplicationRecord

  def self.sanitize_filename(name)
    name.downcase.gsub(%r{[^-_\.\:a-z0-9]}, "_")
  end

  def self.find_for_file_name(file_name)
    self.find_by_file_name(file_name)
  end

  def self.from_file_name(file_name)
    new(file_name: file_name)
  end

  def self.create_or_fetch(width:, height:, file_name:)
    img = self.where(file_name:).first
    img || self.new(file_name:, width:, height:)
  end

  def self.recent(count)
    where("images_id is null").order("updated_at desc").limit(8)
  end


  def is_png?
    self.content_type == "image/png"
  end

  def thumbnail_url
    self.url.sub(/\.(\w+)$/, '_thumb.\\1').sub(%r{/master/}, "/covers/").sub(/\.png$/, '.jpg')
  end

  def download
    downloader = S3::AssetDownloader.new
    asset = downloader.download(self.path_in_bucket)
    DownloadedImage.new(asset)
  end

  def set_dimensions_from(content, type)
    img = ImageManipulator.vips_buffer_from_raw_data(content, type)
    self.width = img.width
    self.height = img.height
  end


end
