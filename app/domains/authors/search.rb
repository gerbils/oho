module Authors::Search
  extend self

  def all_creators
    User
      .select("id, name")
      .where("author = 1 or editor = 1")
      .order(:name)
  end

  def all_creators_like(str) 
    all_creators.where("name like ?", "%#{str}%")
  end

end
