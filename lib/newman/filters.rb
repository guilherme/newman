module Newman 
  module Filters
    class Filter
  
        attr_accessor :action, :type, :application, :pattern
        attr_reader   :matcher

        def initialize(type, pattern, action, application)
          self.type, self.pattern, self.action, self.application = type, pattern, action, application
        end

        def match?(controller)
          matcher.call(controller, self.application)
        end

        protected

        def matcher
          raise NotImplementedError
        end

    end

    class ToFilter < Filter
      
      def initialize(type, pattern, action, application)
        raise NotImplementedError unless type == :tag
        super
      end

      def matcher
        lambda { |controller, application|
          controller.request.to.each do |e| 
            md = e.match(/\+#{application.compile_regex(pattern)}@#{Regexp.escape(controller.domain)}/)
            return md if md
          end

          false
        }
      end
    end

    class SubjectFilter < Filter
      def initialize(type, pattern, action, application) 
        raise NotImplementedError unless type == :match
        super
      end

      def matcher
        lambda { |controller, application|
          md = controller.request.subject.match(/#{application.compile_regex(pattern)}/)

          md || false
        }
      end

    end

    def to(filter_type, pattern, &action)
      filters << ToFilter.new(filter_type, pattern, action, self)
    end

    def subject(filter_type, pattern, &action)
      filters << SubjectFilter.new(filter_type, pattern, action, self)
    end
  end
end
