require 'spec_helper'

describe Mongoid::Follower do

  describe User do

    before do
      @bonnie = User.create
      @clyde = User.create
      @alec = User.create

      @gang = Group.create
    end

    it "should have no follows or followers" do
      @bonnie.follows?(@clyde).should be_false

      @bonnie.follow(@clyde)
      @clyde.follower?(@alec).should be_false
      @alec.follows?(@clyde).should be_false
    end

    it "can follow another User" do
      @bonnie.follow(@clyde)

      @bonnie.follows?(@clyde).should be_true
      @clyde.follower?(@bonnie).should be_true
    end

    it "can unfollow another User" do
      @bonnie.follows?(@clyde).should be_false
      @clyde.follower?(@bonnie).should be_false

      @bonnie.follow(@clyde)
      @bonnie.follows?(@clyde).should be_true
      @clyde.follower?(@bonnie).should be_true

      @bonnie.unfollow(@clyde)
      @bonnie.follows?(@clyde).should be_false
      @clyde.follower?(@bonnie).should be_false
    end

    it "can follow a group" do
      @bonnie.follow(@gang)

      @bonnie.follows?(@gang).should be_true
      @gang.follower?(@bonnie).should be_true
    end

    it "should increment / decrement counters" do
      @clyde.followers_count.should == 0

      @bonnie.follow(@clyde)

      @bonnie.followees_count.should == 1
      @clyde.followers_count.should == 1

      @alec.follow(@clyde)
      @clyde.followers_count.should == 2
      @bonnie.followers_count.should == 0

      @alec.unfollow(@clyde)
      @alec.followees_count.should == 0
      @clyde.followers_count.should == 1

      @bonnie.unfollow(@clyde)
      @bonnie.followees_count.should == 0
      @clyde.followers_count.should == 0
    end
  end
end