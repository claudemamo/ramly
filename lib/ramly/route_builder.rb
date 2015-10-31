module Ramly

  module RouteBuilder

    class Route

      attr_accessor :uri, :pattern, :methods

      def initialize(uri)
        @methods = {}
        @uri = uri
        uri_named_params_pattern = @uri.gsub(/\/{([\w]+)}/) {
          "/(?<#{$1}>[\\w]+)"
        } + '$'

        @pattern = Regexp.new(uri_named_params_pattern)
      end

      def [](method)
        @methods[method]
      end

      def add_method(method, block)
        methods[method] = block
      end

      def to_params(uri)
        uri_named_params = uri.match(@pattern)
        Hash[uri_named_params.names.zip(uri_named_params.captures)].inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo }
      end
    end

    class Routes

      def initialize
        @routes = []
      end

      def <<(route)
        @routes << route
      end

      def [](uri)
        route = @routes.find do |route|
          route.uri == uri ? true : route.pattern =~ uri
        end

        route unless route.nil?
      end

      def has_route?(uri)
        @routes.any? do |route|
          uri.match(route.pattern)
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
        if @routes.has_route? uri
          route = @routes[uri]
          route.add_method(method, block)
        else
          route = Route.new(uri)
          route.add_method(method, block)
          @routes << route
        end
      else
        raise(ImplementedUnknownResource, "Implemented unknown resource for #{method}: #{uri}")
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