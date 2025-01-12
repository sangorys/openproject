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

module MailDigestHelper
  def digest_summary_text(notification_count, mentioned_count)
    mentioned = mentioned_count > 1 ? 'plural' : 'singular'
    notifications = notification_count > 1 ? 'plural' : 'singular'

    summary = I18n.t(:"mail.digests.unread_notification_#{notifications}",
                     number_unread: notification_count).to_s

    unless mentioned_count === 0
      summary << " #{I18n.t(:"mail.digests.including_mention_#{mentioned}",
                            number_mentioned: mentioned_count)}"
    end

    summary
  end

  def digest_notification_timestamp_text(notification, html: true, extended_text: false)
    journal = notification.journal
    user = html ? link_to_user(journal.user, only_path: false) : journal.user.name

    timestamp_text(user, journal, extended_text)
  end

  def digest_comment_text(notification)
    if notification.reason_mail_digest === "mentioned"
      sanitize I18n.t(:'mail.digests.work_packages.mentioned')
    else
      sanitize I18n.t(:'mail.digests.work_packages.comment_added')
    end
  end

  private

  def timestamp_text(user, journal, extended)
    value = journal.initial? ? "created" : "updated"
    if extended
      sanitize(
        "#{I18n.t(:"mail.digests.work_packages.#{value}")} #{I18n.t(:"mail.digests.work_packages.#{value}_at",
                                                                    user: user,
                                                                    timestamp: journal.created_at.strftime(
                                                                      I18n.t(:'time.formats.time')
                                                                    ))}"
      )
    else
      sanitize(I18n.t(:"mail.digests.work_packages.#{value}_at",
                      user: user,
                      timestamp: journal.created_at.strftime(I18n.t(:'time.formats.time'))))
    end
  end
end
