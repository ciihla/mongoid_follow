require 'spec_helper'

describe Mongoid::Follower do

  describe User do

    before do
      @bonnie = User.create(:name => 'Bonnie')
      @clyde = User.create(:name => 'Clyde')
      @alec = User.create(:name => 'Alec')
      @just_another_user = OtherUser.create(:name => 'Another User')

      @gang = Group.create(:name => 'Gang')
    end

    it "should have timestamp" do
      @bonnie.followed_since(@clyde).should be_nil

      @bonnie.follow(@clyde)

      @bonnie.followed_since(@clyde).should_not be_nil
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

    it "should decline to follow self" do
      @bonnie.follow(@bonnie).should be_false
    end

    it "should decline two follows" do
      @bonnie.follow(@clyde)

      @bonnie.follow(@clyde).should be_false
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

    it "should decline unfollow of non-followed User" do
      @bonnie.unfollow(@clyde).should be_false
    end

    it "should decline unfollow of self" do
      @bonnie.unfollow(@bonnie).should be_false
    end

    it "can follow a group" do
      @bonnie.follow(@gang)

      @bonnie.follows?(@gang).should be_true
      @gang.follower?(@bonnie).should be_true
    end

    describe "counting stuff" do
      it "should increment / decrement cache counters" do
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

      it "should allow to count followees by model" do
        @alec.follow(@gang)
        @alec.followees_count.should == 1
        @alec.followees_count_by_model(Group).should == 1

        @alec.follow(@clyde)
        @alec.followees_count.should == 2
        @alec.followees_count_by_model(Group).should == 1
      end

      it "should also allow to count followees by model with dynamic method" do
        @alec.follow(@gang)
        @alec.follow(@clyde)

        @alec.group_followees_count.should == 1
      end

      it "should allow to count followers by model" do
        @just_another_user.follow(@gang)
        @gang.followers_count.should == 1
        @gang.followers_count_by_model(OtherUser).should == 1

        @alec.follow(@gang)
        @gang.followers_count.should == 2
        @gang.followers_count_by_model(OtherUser).should == 1
      end

      it "should also allow to count followers by model with dynamic method" do
        @just_another_user.follow(@gang)
        @alec.follow(@gang)

        @gang.user_followers_count.should == 1
      end
    end

    describe "listing stuff" do
      it "should list all followers" do
        @bonnie.follow(@clyde)
        # @clyde.all_followers.should == [@bonnie] # spec has an error on last #all_followers when this is called

        @alec.follow(@clyde)
        @clyde.all_followers.should == [@bonnie, @alec]
      end

      it "should list all followers by model" do
        @bonnie.follow(@gang)
        @just_another_user.follow(@gang)

        @gang.all_followers.should == [@bonnie, @just_another_user]
        @gang.all_followers_by_model(User).should == [@bonnie]
      end

      it "should list all followers by model with dynamic method" do
        @bonnie.follow(@gang)
        @just_another_user.follow(@gang)

        @gang.all_user_followers(User).should == [@bonnie]
      end

      it "should list all followees" do
        @bonnie.follow(@clyde)
        # @bonnie.all_followees.should == [@clyde] # spec has an error on last #all_followees when this is called

        @bonnie.follow(@gang)
        @bonnie.all_followees.should == [@clyde, @gang]
      end

      it "should list all followees by model" do
        @bonnie.follow(@gang)
        @bonnie.follow(@clyde)

        @bonnie.all_followees.should == [@gang, @clyde]
        @bonnie.all_followees_by_model(User).should == [@clyde]
      end

      it "should list all followees by model with dynamic method" do
        @bonnie.follow(@gang)
        @bonnie.follow(@clyde)

        @bonnie.all_user_followees.should == [@clyde]
      end

      it "should have common followers" do
        @bonnie.follow(@clyde)
        @bonnie.follow(@gang)

        @gang.common_followers_with(@clyde).should == [@bonnie]

        @alec.follow(@clyde)
        @alec.follow(@gang)

        @clyde.common_followers_with(@gang).should == [@bonnie, @alec]
      end

      it "should have common followees" do
        @bonnie.follow(@gang)
        @alec.follow(@gang)

        @alec.common_followees_with(@bonnie).should == [@gang]

        @bonnie.follow(@clyde)
        @alec.follow(@clyde)

        @bonnie.common_followees_with(@alec).should == [@gang, @clyde]
      end
    end

    describe "callback stuff" do
      # Duh... this is a useless spec... Hrmn...
      it "should respond on callbacks" do
        @bonnie.respond_to?('after_follow').should be_true
        @bonnie.respond_to?('after_unfollowed_by').should be_true
        @bonnie.respond_to?('before_follow').should be_false

        @gang.respond_to?('before_followed_by').should be_true
        @gang.respond_to?('after_followed_by').should be_false
      end

      it "should be unfollowed by each follower after destroy" do
        @bonnie.follow(@clyde)
        @alec.follow(@clyde)

        @clyde.destroy

        @bonnie.reload.all_followees.include?(@clyde).should == false
        @alec.reload.all_followees.include?(@clyde).should == false
      end

      it "should be unfollowed after follower destroy" do
        @bonnie.follow(@clyde)
        @alec.follow(@clyde)

        @bonnie.destroy

        @clyde.reload.all_followers.include?(@bonnie).should == false
        @clyde.reload.all_followers.include?(@alec).should == true
      end
    end

  end
end
