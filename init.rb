require 'priority_filter'

ActionController::Base.send(:include, ActionController::Filters::PriorityFilter)
