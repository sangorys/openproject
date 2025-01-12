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

module Users::Scopes
  module HavingReminderMailToSend
    extend ActiveSupport::Concern

    class_methods do
      # Returns all users for which a reminder mails should be sent now. A user will be included if:
      # * That user has an unread notification
      # * The user hasn't been informed about the unread notification before
      # * The user has configured reminder mails to be within the time frame between the provided time and now.
      # This assumes that users only have full hours specified for the times they desire
      # to receive a reminder mail at.
      # @param [DateTime] earliest_time The earliest time to consider as a matching slot. All quarter hours from that time
      #   to now are included.
      #   Only the time part is used which is moved forward to the next quarter hour (e.g. 2021-05-03 10:34:12+02:00 -> 08:45:00).
      #   This is done because time zones always have a mod(15) == 0 minutes offset.
      #   Needs to be before the current time.
      def having_reminder_mail_to_send(earliest_time)
        local_times = local_times_from(earliest_time)

        return none if local_times.empty?

        # Left outer join as not all user instances have preferences associated
        # but we still want to select them.
        recipient_candidates = User
                                 .active
                                 .left_joins(:preference)
                                 .joins(local_time_join(local_times))

        subscriber_ids = Notification
                           .unsent_reminders_before(recipient: recipient_candidates, time: Time.current)
                           .group(:recipient_id)
                           .select(:recipient_id)

        where(id: subscriber_ids)
      end

      def local_time_join(local_times)
        # Joins the times local to the user preferences and then checks whether:
        # * reminders are enabled
        # * any of the configured reminder time is the local time
        # If no time zone is present, utc is assumed.
        # If no reminder settings are present, sending a reminder at 08:00 local time is assumed.
        <<~SQL.squish
          JOIN (
           SELECT * FROM #{arel_table.grouping(Arel::Nodes::ValuesList.new(local_times)).as('t(time, zone)').to_sql}
          ) AS local_times
          ON COALESCE(user_preferences.settings->>'time_zone', 'UTC') = local_times.zone
          AND (
            (
              user_preferences.settings->'daily_reminders'->'times' IS NULL
              AND local_times.time = '08:00:00+00:00'
            )
            OR
            (
              (user_preferences.settings->'daily_reminders'->'enabled')::boolean
              AND user_preferences.settings->'daily_reminders'->'times' ? local_times.time
            )
          )
        SQL
      end

      def local_times_from(earliest_time)
        times = quarters_between_earliest_and_now(earliest_time)

        times_for_zones(times)
      end

      def times_for_zones(times)
        ActiveSupport::TimeZone
          .all
          .map do |z|
            times.map do |time|
              local_time = time.in_time_zone(z)

              # Since only full hours can be configured, we can disregard any local time that is not
              # a full hour.
              next if local_time.min != 0

              [local_time.strftime('%H:00:00+00:00'), z.name.gsub("'", "''")]
            end
          end
          .flatten(1)
          .compact
      end

      def quarters_between_earliest_and_now(earliest_time)
        latest_time = Time.current
        raise ArgumentError if latest_time < earliest_time || (latest_time - earliest_time) > 1.day

        quarters = ((latest_time - earliest_time) / 60 / 15).floor

        (1..quarters).each_with_object([next_quarter_hour(earliest_time)]) do |_, times|
          times << (times.last + 15.minutes)
        end
      end

      def next_quarter_hour(time)
        (time + (time.min % 15 == 0 ? 0.minutes : (15 - (time.min % 15)).minutes))
      end
    end
  end
end
