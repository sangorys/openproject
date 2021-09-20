#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
require 'spec_helper'
require_relative './create_from_journal_job_shared'

describe Notifications::CreateFromModelService, 'message', with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:call) do
    described_class.new(journal).call(send_notifications)
  end

  include_context 'with CreateFromJournalJob context'

  shared_let(:project) { FactoryBot.create(:project) }
  shared_let(:forum) { FactoryBot.create(:forum, project: project) }

  let(:permissions) { [:view_messages] }
  let(:send_notifications) { true }

  let(:resource) do
    FactoryBot.create(:message,
                      forum: forum,
                      parent: root_message)
  end
  let(:journal) { resource.journals.last }
  let(:author) { other_user }
  let(:root_message) do
    FactoryBot.create(:message,
                      forum: forum)
  end

  current_user { other_user }

  before do
    recipient
  end

  describe '#perform' do
    context 'with a newly created message' do
      context 'with the user having registered for all notifications' do
        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: false,
              sent_mail: nil
            }
          end
        end
      end

      context 'with the user having registered for involved notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(involved: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for no notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false)
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and watching the forum' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        before do
          forum.watcher_users << recipient
        end

        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: false,
              sent_mail: nil
            }
          end
        end
      end

      context 'with the user not having registered for watcher notifications and watching the forum' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false)
          ]
        end

        before do
          forum.watcher_users << recipient
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and not watching the forum nor root message' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and watching the root' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        before do
          root_message.watcher_users << recipient
        end

        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: false,
              sent_mail: nil
            }
          end
        end
      end

      context 'with the user not having registered for watcher notifications and watching the root' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false)
          ]
        end

        before do
          root_message.watcher_users << recipient
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for all notifications but lacking permissions' do
        before do
          recipient.members.destroy_all
        end

        it_behaves_like 'creates no notification'
      end
    end

    context 'with an updated message' do
      before do
        resource.subject = 'A new subject'
        resource.save!
      end

      context 'with the user having registered for all notifications' do
        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: false,
              sent_mail: nil
            }
          end
        end
      end

      context 'with the user having registered for involved notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(involved: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for no notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false)
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and watching the forum' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        before do
          forum.watcher_users << recipient
        end

        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: false,
              sent_mail: nil
            }
          end
        end
      end

      context 'with the user not having registered for watcher notifications and watching the forum' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false)
          ]
        end

        before do
          forum.watcher_users << recipient
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and not watching the forum nor root message' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and watching the root' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        before do
          root_message.watcher_users << recipient
        end

        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason: false,
              sent_mail: nil
            }
          end
        end
      end

      context 'with the user not having registered for watcher notifications and watching the root' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:notification_setting, **notification_settings_all_false)
          ]
        end

        before do
          root_message.watcher_users << recipient
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for all notifications but lacking permissions' do
        before do
          recipient.members.destroy_all
        end

        it_behaves_like 'creates no notification'
      end
    end
  end
end
