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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Events
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_default_attributes(params)
      super

      set_default_subject unless model.subject
      set_default_context unless model.context
    end

    def set_default_subject
      # TODO: Work package journal specific.
      # Extract into strategy per event resource
      journable = model.resource.journable

      class_name = journable.class.name.underscore

      model.subject = I18n.t("events.#{class_name.pluralize}.subject.#{model.reason}",
                             **{ class_name.to_sym => journable.to_s })
    end

    def set_default_context
      # TODO: Work package journal specific.
      # Extract into strategy per event resource
      model.context = model.resource.data.project
    end
  end
end