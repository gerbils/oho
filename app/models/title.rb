# == Schema Information
#
# Table name: products
#
#  id                          :integer          not null, primary key
#  announced_on_date           :date
#  author                      :string(255)
#  author_bio                  :text(65535)
#  available_on                :date
#  background_info             :text(65535)
#  beta                        :boolean          default(FALSE)
#  beta_page_count             :integer
#  bisac1                      :string(255)
#  bisac2                      :string(255)
#  bisac3                      :string(255)
#  channel_epub_isbn           :string(20)
#  channel_pdf_isbn            :string(20)
#  channel_price_cad           :decimal(8, 2)
#  channel_price_usd           :decimal(8, 2)
#  code                        :string(255)      not null
#  code_available              :boolean          default(TRUE)
#  color                       :boolean          default(FALSE)
#  competing_titles            :text(65535)
#  contents_and_extracts       :text(65535)
#  copies_per_case             :integer
#  cover_image_uploaded_at     :datetime
#  edition                     :integer          default(1)
#  efile_password              :string(255)
#  errata_locked               :boolean
#  hardcover_isbn              :string(20)
#  hidden                      :boolean          default(TRUE)
#  highlight_description       :text(65535)      not null
#  is_distribution_only        :boolean          default(FALSE)
#  isbn13                      :string(255)
#  key_selling_points          :text(65535)
#  keywords                    :string(255)
#  kindle_edition_isbn         :string(255)
#  layout_name                 :string(255)      default("application")
#  long_description            :text(65535)      not null
#  market_description          :text(65535)
#  one_line_description        :text(65535)
#  ora_category                :string(255)
#  page_count                  :integer
#  prerequisites               :text(65535)
#  print_status                :string(255)
#  pubdate                     :date
#  related_titles              :text(65535)
#  release_to_intl_partners_at :datetime
#  safari_isbn                 :string(20)
#  sales_conf_date             :date
#  series                      :string(255)
#  shelving                    :string(255)
#  show_to_partners            :boolean          default(TRUE)
#  signed_on                   :date
#  skill_level_high            :integer
#  skill_level_low             :integer
#  spine_thickness             :float(24)
#  subtitle                    :string(255)
#  summary_feature_points      :text(65535)
#  tagline                     :string(255)
#  template_name               :string(255)      default("show")
#  title                       :string(255)      not null
#  trim_size                   :string(20)
#  type                        :string(255)
#  upc                         :string(15)
#  url_title                   :string(255)
#  user_level                  :string(255)
#  vat_tax_category            :string(255)      default("professional")
#  was_previous_edition        :string(255)
#  web_highlight               :text(65535)
#  will_sell_like              :text(65535)
#  youtube_code                :string(255)
#  youtube_height              :integer
#  youtube_width               :integer
#  previous_edition_id         :integer
#
# Indexes
#
#  index_products_on_code  (code)
#
class Title < Product
end

