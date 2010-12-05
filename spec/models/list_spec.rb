require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# List:
#     name
#     modifications:
#         action
#         author_id
#         album_id
# 
# User:
#     lists:
#         id
#         name
#         albums_ids
#         accepted_modification_ids
#         rejected_modification_ids


describe List do

  def new_user(name)
    u = User.create(:name => name, :email => "test@test.com")
    raise u.errors.inspect unless u.valid?
    u
  end

  def tricky
    @tricky ||= new_user("tricky")
  end

  def pelicano
    @pelicano ||= new_user("pelicano")
  end

  it "should be created by a user" do
    list = List.new(:name => "a list", :author => tricky)
    list.should be_valid
  end

  describe "created by tricky" do

    before :each do 
      @list = List.create(:name => 'R&B', :author => tricky)
    end

    it "should accept new event from user" do
      @list.add(:album_id => "1", :author => tricky)
      @tricky = User.find(tricky.id)
      user_list = tricky.list_by_id(@list.id)
      user_list.should_not be_nil
      user_list.album_ids.should == ["1"]
      @list.modifications.length.should == 1
      modif = @list.modifications.first
      modif.author_id.should == tricky.id
      modif.action.should == "add"
      modif.album_id.should == "1"
      user_list.accepted_modification_ids.should == [modif.id]
    end

    it "should accept event from others" do
      @list.add(:album_id => "1", :author => tricky)
      @list.add(:album_id => "2", :author => pelicano)
      @tricky = User.find(tricky.id)
      tricky.list_by_id(@list.id).album_ids.should == ["1"]
      pelicano.list_by_id(@list.id).album_ids.should == ["1", "2"]
      tricky.list_by_id(@list.id).pending_modifications.length.should == 1
      pending_modification = tricky.list_by_id(@list.id).pending_modifications.first
      pending_modification.action.should == "add"
      pending_modification.author_id.should == pelicano.id
      pending_modification.album_id.should == "2"
      pending_modification.accept(:author => tricky)
      @tricky = User.find(tricky.id)
      tricky.list_by_id(@list.id).pending_modifications.should be_empty
      tricky.list_by_id(@list.id).album_ids.should == ["1", "2"]
    end

    it "should reject event from others" do
      @list.add(:album_id => "1", :author => tricky)
      @list.add(:album_id => "2", :author => pelicano)
      pending_modification = tricky.list_by_id(@list.id).pending_modifications.first
      pending_modification.reject(:author => tricky)
      tricky.list_by_id(@list.id).pending_modifications.should be_empty
      tricky.list_by_id(@list.id).album_ids.should == ["1"]
    end

    it "should accept removal from others" do
      @list.add(:album_id => "1", :author => tricky)
      @list.add(:album_id => "2", :author => tricky)
      @list.remove(:album_id => "1", :author => pelicano)
      tricky.list_by_id(@list.id).album_ids.should == ["1", "2"]
      pelicano.list_by_id(@list.id).album_ids.should == ["2"]
      pending_modification = tricky.list_by_id(@list.id).pending_modifications.first
      pending_modification.action.should == "remove"
      pending_modification.author_id.should == pelicano.id
      pending_modification.album_id.should == "1"
      pending_modification.accept(:author => tricky)
      tricky.list_by_id(@list.id).pending_modifications.should be_empty
      tricky.list_by_id(@list.id).album_ids.should == ["2"]
    end

  end

end
