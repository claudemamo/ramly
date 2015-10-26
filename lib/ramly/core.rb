require './lib/ramly/route_builder'

module Ramly

  class Base
    extend RouteBuilder

    attr_accessor :env, :request, :response, :params, :raml

    @params = {}

    def initialize(app = nil)
      super()
      @app = app
      yield self if block_given?
    end

    def call(env)
      @request = Rack::Request.new(env)
      @params = @request.params

      @response = Rack::Response.new
      if (self.class.routes.has_key?(@request.path_info) && self.class.routes[@request.path_info].has_key?(@request.request_method))
        block = self.class.routes[@request.path_info][@request.request_method]
        @response.write instance_eval(&block)
        @response.status = 200
      else
        @response.status = 403
      end

      @response.finish
    end

    class << self
      attr_accessor :routes, :run, :environment

      def run?
        !test?
      end

      def test?
        environment == :test
      end

      def prototype
        @prototype ||= new
      end

      def call(env)
        prototype.call(env)
      end

      alias new! new unless method_defined? :new!

      def new(*args, &bk)
        instance = new!(*args, &bk)
        Wrapper.new(build(instance).to_app, instance)
      end

      def build(app)
        builder = Rack::Builder.new
        # setup_default_middleware builder
        # setup_middleware builder
        builder.run app
        builder
      end

      def get(uri, opts = {}, &block)
        add_route(uri, 'GET', &block)
      end

      def delete(uri, opts = {}, &block)
        add_route(uri, 'DELETE', &block)
      end

      def post(uri, opts = {}, &block)
        add_route(uri, 'POST', &block)
      end

      def put(uri, opts = {}, &block)
        add_route(uri, 'PUT', &block)
      end

      def run!
        [:INT, :TERM].each do |signal|
          trap(signal) do
            stop
          end
        end

        Rack::Handler::WEBrick.run(self)
      end

      def stop
        return unless running?
        # Use Thin's hard #stop! if available, otherwise just #stop.
        running_server.respond_to?(:stop!) ? running_server.stop! : running_server.stop
        $stderr.puts "== Sinatra has ended his set (crowd applauds)" unless handler_name =~/cgi/i
        set :running_server, nil
        set :handler_name, nil
      end

      def set(option, value = (not_set = true), ignore_setter = false, &block)
        raise ArgumentError if block and !not_set
        value, not_set = block, false if block

        if not_set
          raise ArgumentError unless option.respond_to?(:each)
          option.each { |k,v| set(k, v) }
          return self
        end

        if respond_to?("#{option}=") and not ignore_setter
          return __send__("#{option}=", value)
        end

        setter = proc { |val| set option, val, true }
        getter = proc { value }

        case value
          when Proc
            getter = value
          when Symbol, Fixnum, FalseClass, TrueClass, NilClass
            getter = value.inspect
          when Hash
            setter = proc do |val|
              val = value.merge val if Hash === val
              set option, val, true
            end
        end

        define_singleton("#{option}=", setter) if setter
        define_singleton(option, getter) if getter
        define_singleton("#{option}?", "!!#{option}") unless method_defined? "#{option}?"
        self
      end

      # Dynamically defines a method on settings.
      def define_singleton(name, content = Proc.new)
        # replace with call to singleton_class once we're 1.9 only
        (class << self; self; end).class_eval do
          undef_method(name) if method_defined? name
          String === content ? class_eval("def #{name}() #{content}; end") : define_method(name, &content)
        end
      end


    end

    set :raml, 'api.raml'

  end

end

