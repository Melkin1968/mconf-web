# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe RecentActivity do
  let(:default_key) { "space.created" }

  describe "#user_activity" do
    let(:user) { FactoryGirl.create(:user) }

    context "returns the activities in his room" do
      let(:another_user) { FactoryGirl.create(:user) }
      before do
        @activity1 = RecentActivity.create(key: default_key, owner: user.bigbluebutton_room)
        @activity2 = RecentActivity.create(key: default_key, owner: another_user.bigbluebutton_room)
      end
      subject { RecentActivity.user_activity(user) }
      it { subject.length.should be(1) }
      it { subject[0].should eq(@activity1) }
    end

    context "returns the activities in his spaces" do
      let(:space1) { FactoryGirl.create(:space_with_associations) }
      let(:space2) { FactoryGirl.create(:space_with_associations) }
      let(:space3) { FactoryGirl.create(:space_with_associations) }
      before do
        space1.add_member!(user, 'User')
        space2.add_member!(user, 'Admin')
        @activity1 = RecentActivity.create(key: default_key, owner: space1)
        @activity2 = RecentActivity.create(key: default_key, owner: space2)
        @activity3 = RecentActivity.create(key: default_key, owner: space3)
      end
      subject { RecentActivity.user_activity(user) }
      it { subject.length.should be(2) }
      it { subject[0].should eq(@activity1) }
      it { subject[1].should eq(@activity2) }
    end

    context "returns the activities in his spaces when the space is a 'trackable'" do
      let(:space1) { FactoryGirl.create(:space_with_associations) }
      let(:space2) { FactoryGirl.create(:space_with_associations) }
      let(:space3) { FactoryGirl.create(:space_with_associations) }
      before do
        space1.add_member!(user, 'User')
        space2.add_member!(user, 'Admin')
        @activity1 = RecentActivity.create(key: default_key, trackable: space1)
        @activity2 = RecentActivity.create(key: default_key, trackable: space2)
        @activity3 = RecentActivity.create(key: default_key, trackable: space3)
      end
      subject { RecentActivity.user_activity(user) }
      it { subject.length.should be(2) }
      it { subject[0].should eq(@activity1) }
      it { subject[1].should eq(@activity2) }
    end

    context "returns the activities in the rooms of his spaces" do
      let(:space1) { FactoryGirl.create(:space_with_associations) }
      let(:space2) { FactoryGirl.create(:space_with_associations) }
      let(:space3) { FactoryGirl.create(:space_with_associations) }
      before do
        space1.add_member!(user, 'User')
        space2.add_member!(user, 'Admin')
        @activity1 = RecentActivity.create(key: default_key, owner: space1.bigbluebutton_room)
        @activity2 = RecentActivity.create(key: default_key, owner: space2.bigbluebutton_room)
        @activity3 = RecentActivity.create(key: default_key, owner: space3.bigbluebutton_room)
      end
      subject { RecentActivity.user_activity(user) }
      it { subject.length.should be(2) }
      it { subject[0].should eq(@activity1) }
      it { subject[1].should eq(@activity2) }
    end

    context "rejects keys if they are informed" do
      let(:space) { FactoryGirl.create(:space_with_associations) }
      before do
        space.add_member!(user, 'User')
        @activity1 = RecentActivity.create(owner: space, key: "key1")
        @activity2 = RecentActivity.create(owner: space, key: "key2")
        @activity3 = RecentActivity.create(owner: space, key: "key3")
      end
      subject { RecentActivity.user_activity(user, ["key1", "key2"]) }
      it { subject.length.should be(1) }
      it { subject[0].should eq(@activity3) }
    end

    context "rejects some types of activities by default" do
      before do
        RecentActivity.create(owner: user, key: "user.created")
        RecentActivity.create(owner: user, key: "ldap.user.created")
        RecentActivity.create(owner: user, key: "shibboleth.user.created")
        RecentActivity.create(owner: user, key: "user.approved")
      end
      subject { RecentActivity.user_activity(user) }
      it { subject.length.should be(0) }
    end
  end

  describe "#user_public_activity" do
    let(:user) { FactoryGirl.create(:user) }

    context 'test it returns only activities performed by the user' do
      let(:user2) { FactoryGirl.create(:user) }
      let(:space) { FactoryGirl.create(:space_with_associations, public: true) }
      let(:private_space) { FactoryGirl.create(:space_with_associations, public: false) }

      before {
        posts = [ FactoryGirl.create(:post, space: space), FactoryGirl.create(:post, space: space),
                  FactoryGirl.create(:post, space: private_space), FactoryGirl.create(:post, space: private_space)
         ]
        # pending: webconf activities

        space.add_member!(user)
        space.add_member!(user2)
        private_space.add_member!(user)
        private_space.add_member!(user2)

        @activities = [
          space.new_activity(:update, user),
          space.new_activity(:join, user),
          posts[0].new_activity(:create, user),
          posts[2].new_activity(:create, user),
          private_space.new_activity(:join, user),

          space.new_activity(:update, user2),
          posts[1].new_activity(:create, user2),
          posts[3].new_activity(:create, user2),
          private_space.new_activity(:join, user2)
        ]
        # hack, we do this because we need it to use our class RecentActivity and not PublicActivity
        @activities.map!{|a| RecentActivity.find(a.id)}
      }

      it { RecentActivity.user_public_activity(user).size.should be(5) }
      it { RecentActivity.user_public_activity(user2).size.should be(4) }
      it { RecentActivity.user_public_activity(user).should include(*@activities[0..4]) }
      it { RecentActivity.user_public_activity(user2).should include(*@activities[5..9]) }

      context "return only activities in certain spaces with 'in_spaces'" do
        context "with no spaces return no activities" do
          it { RecentActivity.user_public_activity(user, in_spaces: []).size.should be(0) }
          it { RecentActivity.user_public_activity(user2, in_spaces: []).size.should be(0) }
        end

        context "when there are no activities for the spaces" do
          it { RecentActivity.user_public_activity(user, in_spaces: [FactoryGirl.create(:space)]).size.should be(0) }
          it { RecentActivity.user_public_activity(user2, in_spaces: [FactoryGirl.create(:space)]).size.should be(0) }
        end

        context "when there are some activities for the space" do
          it { RecentActivity.user_public_activity(user, in_spaces: [space]).size.should be(3) }
          it { RecentActivity.user_public_activity(user2, in_spaces: [space]).size.should be(2) }

          it { RecentActivity.user_public_activity(user, in_spaces: [private_space]).size.should be(2) }
          it { RecentActivity.user_public_activity(user2, in_spaces: [private_space]).size.should be(2) }

          it { RecentActivity.user_public_activity(user, in_spaces: [space, private_space]).should eq(RecentActivity.user_public_activity(user))  }
          it { RecentActivity.user_public_activity(user2, in_spaces: [space, private_space]).should eq(RecentActivity.user_public_activity(user2))  }
        end
      end
    end

    context "ignores declined join requests" do
      before {
        RecentActivity.should_receive(:user_activity) { |user, arg|
          arg.should be_an_instance_of(Array)
          arg.should include("space.decline")
        }.and_return(RecentActivity.none)
      }
      it { RecentActivity.user_public_activity(user).should be_blank }
    end
  end
end
