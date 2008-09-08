module ActionController
  module Filters
    module PriorityFilter
      
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def extract_options(*methods, &block)
          methods.flatten!
          options = methods.extract_options!
          methods << block if block_given?
          return methods, options
        end
        
        def add_priority_filter(default_priority, filter_type, *filters, &block)
          
          filters, options = extract_options(filters)
          
          f = priority_filters
          l = last_priority_filters
          
          priority = options[:priority] ||= default_priority
          priority = 0 if priority == :first
          
          if priority != :last and !priority.is_a? Integer and priority < 0
            throw "Invalid priority, must be a positive integer, :first or :last"
          end
          
          options.reject! { |k, v| k == :priority }
          
          new_filters = {:filters => filters, :options => options, :block => block, :type => filter_type}
          if priority == :last
            l << new_filters
          elsif priority > f.length - 1
            f.insert priority, [new_filters]
          else
            f[priority] ||= Array.new
            f[priority] << new_filters
          end
          
          rebuild_filter_chain
          
        end
        
        def rebuild_filter_chain
          filter_chain.clear
          priority_filters.flatten.compact.map do |filters|
           filter_chain.append_filter_to_chain [filters[:filters], filters[:options]], filters[:type], &filters[:block]
          end
          
          last_priority_filters.flatten.compact.map do |filters|
           filter_chain.append_filter_to_chain [filters[:filters], filters[:options]], filters[:type], &filters[:block]
          end
          
          skip_filters.each do |filters|
            filter_chain.skip_filter_in_chain(filters[:filters], &filters[:test])
          end
        end
        
        
        def append_before_filter(*filters, &block)
          add_priority_filter(1, :before, *filters, &block)
        end
        
        def append_after_filter(*filters, &block)
          add_priority_filter(1, :after, *filters, &block)
        end
        
        def append_around_filter(*filters, &block)
          add_priority_filter(1, :around, *filters, &block)
        end
        
        alias_method :before_filter, :append_before_filter
        alias_method :after_filter, :append_after_filter
        alias_method :around_filter, :append_around_filter
        
        def prepend_before_filter(*filters, &block)
          add_priority_filter(:first, :before, *filters, &block)
        end
        
        def prepend_after_filter(*filters, &block)
          add_priority_filter(:first, :after, *filters, &block)
        end
        
        def prepend_around_filter(*filters, &block)
          add_priority_filter(:first, :around, *filters, &block)
        end
        
        
        def skip_filter(*filters)
          skip_filters << {:filters => filters}
          rebuild_filter_chain
        end
        
        def skip_before_filter(*filters)
          skip_filters << {:filters => filters, :test => :before?}
          rebuild_filter_chain
        end
        
        def skip_after_filter(*filters)
          skip_filters << {:filters => filters, :test => :after?}
          rebuild_filter_chain
        end
        
        
        def priority_filters
          @priority_filters ||= (self != ActionController::Base ? deep_clone(superclass.priority_filters) : [])
        end
        
        def last_priority_filters
          @last_priority_filters ||= (self != ActionController::Base ? deep_clone(superclass.last_priority_filters) : [])
        end
        
        def skip_filters
          @skip_filters ||= (self != ActionController::Base ? deep_clone(superclass.skip_filters) : [])
        end
        
        private
        
        def deep_clone(array)
          array = array.clone
          array.map!(&:clone)
        end
        
      end
      
    end
  end
end