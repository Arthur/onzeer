class UserList

  # include MongoMapper::EmbeddedDocument
  include MongoRecord

  key :list_id    #, String, :required => true
  key :name       #, String, :required => true
  key :album_ids  #, Array
  key :accepted_modification_ids  #, Array
  key :rejected_modification_ids  #, Array

  attr_accessor :user

  def accept(modification)
    if modification.action == "add"
      album_ids << modification.album_id
    else
      album_ids.delete(modification.album_id)
    end
    accepted_modification_ids << modification.id
    RAILS_DEFAULT_LOGGER.debug "accepted_modification #{modification.id} by #{user.id}"
    user.save
  end

  def reject(modification)
    if modification.action == "remove"
      album_ids << modification.album_id
    else
      album_ids.delete(modification.album_id)
    end
    rejected_modification_ids << modification.id
    user.save
  end

  def list
    @list ||= List.find(list_id)
  end

  def albums
    @albums ||= album_ids.map{|id| Album.find(id)}.compact
  end

  def pending_modifications(reload = false)
    @pending_modifications = nil if reload
    @pending_modifications ||= list.modifications.reject{|m| accepted_modification_ids.include?(m.id) || rejected_modification_ids.include?(m.id) }.each{|m| m.list = list}
  end

  def to_param
    id
  end

end
