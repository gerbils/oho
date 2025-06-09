module Royalties::Shared

  def excel_file_attached?(file)
    case
    when !file.attached?
      "File is not attached"
    when file.content_type !~ /vnd.ms-excel.sheet|officedocument.spreadsheetml/
      "Mime type #{file.content_type} is not an Excel sheet"
    else
      nil
    end
  end

  def open_spreadsheet(buffer, extension)
    file = Tempfile.new('upload')
    begin
      file.binmode
      file.write(buffer)
      file.close
      xls = Roo::Spreadsheet.open(file.path, extension:)
    ensure
      file.unlink
    end
    xls.sheet(0)
  end

end

