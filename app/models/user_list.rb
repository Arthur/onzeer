class UserList

  include MongoMapper::EmbeddedDocument

  key :list_id, String, :required => true
  key :name, String, :required => true
  key :album_ids, Array
  key :accepted_modification_ids, Array
  key :rejected_modification_ids, Array

  attr_accessor :user

  def accept(modification)
    album_ids << modification.album_id
    accepted_modification_ids << modification.id
    user.save
  end

end
