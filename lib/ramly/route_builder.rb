module Ramly

  module RouteBuilder
    #
    # class Methods
    #
    #   attr_accessor :method, :block
    #
    #   def []=(key, value)
    #     @method = key
    #     @block = value
    #   end
    #
    # end

    class Route

      attr_accessor :uri, :pattern

      def initialize(uri)
        @uri = uri
        @pattern = Regexp.new(@uri.gsub(/\/{[\w]+}/, '\/[\w]+$'))
        # puts @pattern
      end

      # def ==(uri)
      #   puts uri
      # end

    end

    class Routes

      def initialize
        @routes = {}
      end

      def []=(uri, methods)
        @routes[Route.new(uri)] = methods
      end

      def [](uri)
        route = @routes.find do |route, methods|
          route.uri == uri ? true : route.pattern =~ uri
        end

        route[1] unless route == nil
      end

      def has_key?(uri)
        @routes.any? do |route, methods|
          route.pattern =~ uri
        end
      end

    end

    def add_route(uri, method, &block)
      begin
        data = YAML.load(raml)
        root = Raml::Root.new data
      rescue
        root = Raml.parse_file(raml)
      end

      @routes = Routes.new

      if is_valid_route?(root.resources, method, uri)
        if @routes.has_key? uri
          @routes[uri][method] = block
        else
          @routes[uri] = {}
          puts uri
          @routes[uri][method] = block
        end
      else
        throw 'Unexpected URI ' + method + ' ' + uri
      end
    end

    private

    def is_valid_route?(resources, expected_method, expected_uri, actual_uri = '/')
      is_valid = false
      if resources.is_a?(Raml::Resource)
        resources.methods.each do |actual_method, _value|
          if (actual_method.casecmp(expected_method)) && (expected_uri == actual_uri)
            is_valid = true
          end
        end
      else
        resources.each do |uri, resource|
          if (is_valid_route?(resource, expected_method, expected_uri, uri))
            is_valid = true
          end
        end
      end

      is_valid
    end

  end
end