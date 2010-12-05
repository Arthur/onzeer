class Modification

  include MongoMapper::EmbeddedDocument
  include Timestamp
  # embedded_in :list
  attr_accessor :list

  belongs_to :author, :class_name => "User"
  belongs_to :album
  key :author_id, String, :required => true
  key :album_id, String, :required => true
  key :action, String, :required => true # add or remove

  def accept(params)
    author_id = params[:author_id]
    author_id ||= params[:author] && params[:author].id
    raise "missing :author_id or author" unless author_id
    author = params[:author] || User.find(author_id)
    author.list_by_id(self.list.id).accept(self)
  end

end
