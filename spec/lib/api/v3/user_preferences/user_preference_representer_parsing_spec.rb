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

describe ::API::V3::UserPreferences::UserPreferenceRepresenter,
         'parsing' do
  subject(:parsed) { representer.from_hash request_body }

  include ::API::V3::Utilities::PathHelper

  let(:preference) { OpenStruct.new }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(preference, current_user: user) }

  describe 'notification_settings' do
    let(:request_body) do
      {
        'notifications' => [
          {
            'all' => true,
            '_links' => {
              'project' => {
                'href' => '/api/v3/projects/1'
              }
            }
          },
          {
            'all' => false,
            'mentioned' => true,
            '_links' => {
              'project' => {
                'href' => nil
              }
            }
          }
        ]
      }
    end

    it 'parses them into an array of structs' do
      expect(subject.notification_settings).to be_a Array
      expect(subject.notification_settings.length).to eq 2
      in_project, global = subject.notification_settings

      expect(in_project[:project_id]).to eq "1"
      expect(in_project[:all]).to be_truthy

      expect(global[:project_id]).to eq nil
      expect(global[:all]).to eq false
      expect(global[:mentioned]).to eq true
    end
  end

  describe 'daily_reminders' do
    let(:request_body) do
      {
        "dailyReminders" => {
          "enabled" => true,
          "times" => %w[07:00 15:00 18:00:00+00:00]
        }
      }
    end

    it 'parses the times into full iso8601 time format' do
      expect(parsed.daily_reminders)
        .to eql({
                  "enabled" => true,
                  "times" => %w[07:00:00+00:00 15:00:00+00:00 18:00:00+00:00]
                })
    end
  end
end
