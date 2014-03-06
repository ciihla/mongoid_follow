module Mongoid
  module Followee
    extend ActiveSupport::Concern

    included do |base|
      after_destroy :reset_followers

      base.has_many :followers, :class_name => 'Follow', :as => :followee, :dependent => :destroy
    end

    # know if self is followed by model
    #
    # Example:
    # => @clyde.follower?(@bonnie)
    # => true
    def follower?(model, relation = "follow")
      0 < self.followers.where(follower_type: model.class.name, :follower_id => model.id, relation: relation).limit(1).count
    end

    def all_followers(relation = "follow")
      followers.by_relation(relation).all.collect do |f|
        f.follower
      end
    end

    # get followers count
    # Note: this is a cache counter
    #
    # Example:
    # => @bonnie.followers_count
    # => 1
    def followers_count
      self.followers.count
    end

    private
    # unfollow by each follower
    def reset_followers
      Follow.where(:follower_id => self.id).destroy_all
    end

  end
end
