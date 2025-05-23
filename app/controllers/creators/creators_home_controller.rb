require_relative "./creators_base_controller.rb"
class Creators::CreatorsHomeController < Creators::CreatorsBaseController
  def index
    @summary = ::Authors::Info.summary(@effective_user)
    unless @summary[:pip]
      flash.now[:note] = "No author information associated with this email address"
    end
  end
end
