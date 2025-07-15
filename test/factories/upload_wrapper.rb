FactoryBot.define do
  factory :upload_wrapper do
    after(:build) do |uw|
        # Create a temporary file to simulate an uploaded file
        temp_file = Tempfile.new(['test_upload', '.txt'])
        temp_file.write("This is a test file.")
        temp_file.rewind

        # Use Rack::Test::UploadedFile to simulate an uploaded file
        uw.file.attach(
          io: temp_file,
          filename: 'some-temp-file.txt',
          content_type: 'text/plain'
        )

        # Clean up the temporary file after the test run
        temp_file.unlink
    end
  end
end
