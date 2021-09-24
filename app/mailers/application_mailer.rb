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

class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  helper :application, # for format_text
         :work_packages, # for css classes
         :custom_fields # for show_value

  include OpenProject::LocaleHelper

  # Send all delayed mails with the following job
  self.delivery_job = ::Mails::MailerJob

  # wrap in a lambda to allow changing at run-time
  default from: Proc.new { Setting.mail_from }

  class << self
    # Activates/deactivates email deliveries during +block+
    def with_deliveries(temporary_state = true, &_block)
      old_state = ActionMailer::Base.perform_deliveries
      ActionMailer::Base.perform_deliveries = temporary_state
      yield
    ensure
      ActionMailer::Base.perform_deliveries = old_state
    end

    def generate_message_id(object, user)
      # id + timestamp should reduce the odds of a collision
      # as long as we don't send multiple emails for the same object
      journable = object.is_a?(Journal) ? object.journable : object

      timestamp = mail_timestamp(object)
      hash = 'openproject'\
           '.'\
           "#{journable.class.name.demodulize.underscore}"\
           '-'\
           "#{user.id}"\
           '-'\
           "#{journable.id}"\
           '.'\
           "#{timestamp.strftime('%Y%m%d%H%M%S')}"
      host = Setting.mail_from.to_s.gsub(%r{\A.*@}, '')
      host = "#{::Socket.gethostname}.openproject" if host.empty?
      "#{hash}@#{host}"
    end

    def mail_timestamp(object)
      object.send(object.respond_to?(:created_at) ? :created_at : :updated_at)
    end

    def host
      if OpenProject::Configuration.rails_relative_url_root.blank?
        Setting.host_name
      else
        Setting.host_name.to_s.gsub(%r{/.*\z}, '')
      end
    end

    def protocol
      Setting.protocol
    end

    def default_url_options
      options = super.merge host: host, protocol: protocol
      if OpenProject::Configuration.rails_relative_url_root.present?
        options[:script_name] = OpenProject::Configuration.rails_relative_url_root
      end

      options
    end
  end

  def mail(headers = {}, &block)
    block ||= method(:default_formats_for_setting)
    super(headers, &block)
  end

  def message_id(object, user)
    headers['Message-ID'] = "<#{self.class.generate_message_id(object, user)}>"
  end

  def references(object, user)
    headers['References'] = "<#{self.class.generate_message_id(object, user)}>"
  end

  # Prepends given fields with 'X-OpenProject-' to save some duplication
  def open_project_headers(hash)
    hash.each { |key, value| headers["X-OpenProject-#{key}"] = value.to_s }
  end

  private

  def default_formats_for_setting(format)
    format.html unless Setting.plain_text_mail?
    format.text
  end

  def send_mail(user, subject)
    with_locale_for(user) do
      mail to: user.mail, subject: subject
    end
  end
end

##
# Interceptors
#
# These are registered in config/initializers/register_mail_interceptors.rb
#
# Unfortunately, this results in changes on the interceptor classes during development mode
# not being reflected until a server restart.

class DefaultHeadersInterceptor
  def self.delivering_email(mail)
    mail.headers(default_headers)
  end

  def self.default_headers
    {
      'X-Mailer' => 'OpenProject',
      'X-OpenProject-Host' => Setting.host_name,
      'X-OpenProject-Site' => Setting.app_title,
      'Precedence' => 'bulk',
      'Auto-Submitted' => 'auto-generated'
    }
  end
end

class DoNotSendMailsWithoutReceiverInterceptor
  def self.delivering_email(mail)
    receivers = [mail.to, mail.cc, mail.bcc]
    # the above fields might be empty arrays (if entries have been removed
    # by another interceptor) or nil, therefore checking for blank?
    mail.perform_deliveries = false if receivers.all?(&:blank?)
  end
end
