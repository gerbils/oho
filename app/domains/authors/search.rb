module Authors::Search
  extend self

  def all_creators
    User
      .select("id, name, email")
      .where("author = 1 or editor = 1")
      .order(:name)
  end

  def all_creators_like(str)
    all_creators.where("name like ? or email like ?", "%#{str}%", "%#{str}%")
  end

end
