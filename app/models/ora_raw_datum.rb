# == Schema Information
#
# Table name: ora_raw_data
#
#  id             :integer          not null, primary key
#  description    :string(255)
#  gross_dollars  :decimal(8, 2)
#  gross_units    :integer
#  imported_at    :datetime
#  invoice        :string(20)
#  net_dollars    :decimal(8, 2)
#  net_units      :integer
#  post_date      :date
#  product_code   :string(20)
#  return_dollars :decimal(8, 2)
#  return_units   :integer
#  saleto         :string(20)
#  ora_batch_id   :integer
#  sku_id         :integer
#
# Indexes
#
#  fk_ora_raw_data_ora_batch_id  (ora_batch_id)
#  fk_ora_raw_data_sku_id        (sku_id)
#
# Foreign Keys
#
#  fk_ora_raw_data_ora_batch_id  (ora_batch_id => ora_batches.id)
#  fk_ora_raw_data_sku_id        (sku_id => skus.id)
#
class OraRawDatum < LegacyRecord
end
