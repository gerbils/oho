json.extract! upload, :id, :UploadChannel_id, :uploaded_at, :description, :imported_at, :uploaded_file, :created_at, :updated_at
json.url upload_url(upload, format: :json)
json.uploaded_file url_for(upload.uploaded_file)
