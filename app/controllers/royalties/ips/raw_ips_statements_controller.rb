class Royalties::Ips::RawIpsStatementsController < ApplicationController

  before_action :set_statement, only: [ :show ]

  def show
  end

  def update
    spreadsheets = params.expect(:spreadsheets)
    Royalties::Ips::UploadRevenueDetailsHandler.perform(@upload.id)

  end

  private
    def set_statement
      @statement = RawIpsStatement.find(params.expect(:id))
    end
end

