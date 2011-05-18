class Post

  include MongoMapper::Document
  include Timestamp
  timestamps

  key :title, String, :required => true
  key :body, String, :required => true
  key :author_id, String, :required => true
  belongs_to :author, :class_name => "User"

  many :comments

  before_save :timestamps_in_comments

  def timestamps_in_comments
    current_time = Time.now.utc
    comments.each do |comment|
      comment.created_at ||= current_time
      comment.updated_at ||= current_time
    end
  end

end
