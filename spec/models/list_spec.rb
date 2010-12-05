require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe List do

  def new_user(name)
    User.new(:name => name)
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
      user_list = tricky.list_by_id(@list.id)
      user_list.album_ids.should == ["1"]
      @list.modifs.should have(1)
      modif = @list.modifs.first
      modif.author_id.should == tricky.id
      modif.action.should == "add"
      modif.album_id.should == "1"
      user_list.modif_acceptance_ids.should == [modif.id]
    end

    it "should accept event from others" do
      @list.add(:album_id => "1", :author => tricky)
      @list.add(:album_id => "2", :author => pelicano)
      tricky.list_by_id(@list.id).album_ids.should == ["1"]
      pelicano.list_by_id(@list.id).album_ids.should == ["1", "2"]
      tricky.list_by_id(@list.id).pending_modifications.should have(1)
      pending_modification = tricky.list_by_id(@list.id).pending_modifications.first
      pending_modification.action.should == "add"
      pending_modification.author_id.should == pelicano.id
      pending_modification.album_id.should == "2"
      pending_modification.accept(:author => tricky)
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

  end

end
