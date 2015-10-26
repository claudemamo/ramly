module Ramly

  module RouteBuilder

    def add_route(uri, method, &block)
      begin
        data = YAML.load(raml)
        root = Raml::Root.new data
      rescue
        root = Raml.parse_file(raml)
      end

      @routes = {}

      if is_valid_route?(root.resources, method, uri)
        if @routes.has_key? uri
          @routes[uri][method] = block
        else
          @routes[uri] = {}
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
          if (actual_method.casecmp(expected_method)) && (actual_uri == expected_uri)
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