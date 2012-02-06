module Newman 
  class Application
    include Filters

    
    def initialize(&block)
      self.filters  = []
      self.matchers   = {}
      self.extensions = []

      instance_eval(&block) if block_given?
    end

    def call(params)
      controller = Controller.new(params)      
      extensions.each { |mod| controller.extend(mod) }
      trigger_callbacks(controller)
    end

    def default(&callback)
      self.default_callback = callback
    end

    def use(extension)
      extensions << extension
    end

    def helpers(&block)
      extensions << Module.new(&block)
    end

    def match(id, pattern)
      matchers[id.to_s] = pattern
    end

    def compile_regex(pattern)
      Regexp.escape(pattern)
                    .gsub(/\\{(.*?)\\}/) { |m| "(?<#{$1}>#{matchers[$1]})" } 
    end

    private

    attr_accessor :filters, :default_callback, :matchers, :extensions


    def trigger_callbacks(controller)
      matched_filters = filters.select { |filter| filter.match?(controller) }

      if matched_filters.empty?
        controller.instance_exec(&default_callback) 
      else
        matched_filters.each do |filter|
          controller.perform(filter)
        end
      end
    end
  end
end
