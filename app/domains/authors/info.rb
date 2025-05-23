module Authors::Info
  extend self

  def summary(user)
    result = {
      user: {
        email: user.email
      }
    }

    if user.author?
      result[:pip]      = load_pip_info(user)
      result[:calendar] = load_calendar(user)
      result[:titles]   = user.titles.pluck("code").sort
    end

    result
  end


  private

  def load_pip_info(user)
    user.author_details
  end

  def load_calendar(user)
    user.author_calendar_items.where("start_date > ?", 5.days.ago).order(:start_date)
  end
end
