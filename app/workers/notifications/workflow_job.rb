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

# Governs the workflow of how journals are passed through:
#   1) The notifications for any event (e.g. journal creation) is to be created as fast as possible
#      so that it becomes visible as an in app notification. If the resource passed in is indeed a journal,
#      it might get replaced later on (by a subsequent journal). This will lead to notifications being removed.
#   2) After the journal aggregation time has passed as well as the desired delay, the direct email is sent out.
#   3) At the same time (TODO: but it could already have been triggered after the aggregation time has passed)
#      the digest is scheduled.
# This order has to be kept to ensure that the notifications are created before email sending is attempted. If it weren't
# guaranteed, with the notifications created in one job and the mails send in another, the mail sending job might get executed
# without any notifications being created which would result in no emails being sent at all. An alternative would be to
# decouple notification creation and mail sending from another. But then, in app notifications being read could not prevent
# mails being sent out.
class Notifications::WorkflowJob < ApplicationJob
  include ::StateMachineJob

  queue_with_priority :notification

  # In case a resource (e.g. journal) cannot be deserialized (which means fetching it from the db)
  # the resource has been removed which might happen. In that case, no notifications
  # need to be sent out any more.
  discard_on ActiveJob::DeserializationError

  state :create_notifications,
        to: :send_mails do |resource, send_notification|
    Notifications::CreateFromModelService
      .new(resource)
      .call(send_notification)
      .all_results
      .map(&:id)
  end

  state :send_mails,
        wait: -> { Setting.journal_aggregation_time_minutes.to_i.minutes } do |*notification_ids|
    next unless notification_ids

    Notification
      .where(id: notification_ids)
      .unsent_mail
      .where(reason: NotificationSetting.mail_reasons)
      .each do |notification|
        Notifications::MailService
          .new(notification)
          .call
      end
    end
  end
end
