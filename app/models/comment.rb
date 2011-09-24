class Comment

  include MongoEmbeddedRecord
  key :author_id
  key :body
  key :created_at

  def author
    @author ||= User.find(author_id)
  end

  def author=(author)
    self.author_id = author && author.id
    @author = author
  end

end
