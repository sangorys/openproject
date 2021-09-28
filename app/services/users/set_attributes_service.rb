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

module Users
  class SetAttributesService < ::BaseServices::SetAttributes
    include ::HookHelper

    private

    def set_attributes(params)
      set_preferences params.delete(:pref)

      super(params)
    end

    def set_default_attributes(_params)
      # Assign values other than mail to new_user when invited
      if model.invited? && model.valid_attribute?(:mail)
        ::UserInvitation.assign_user_attributes model
      end

      initialize_notification_settings unless model.notification_settings.any?
    end

    def set_preferences(user_preferences)
      model.pref.attributes = user_preferences if user_preferences
    end

    def initialize_notification_settings
      model.notification_settings.build(involved: true, mentioned: true, watched: true)
    end
  end
end
