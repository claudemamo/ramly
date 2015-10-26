require 'raml'
require 'rack'
require './lib/ramly/core'

module Ramly

  def self.new(base = Base, &block)
    base = Class.new(base)
    base.class_eval(&block) if block_given?
    base
  end

  def self.delegate(*methods)
    methods.each do |method|
      define_method(method) do |*args, &block|
        Base.send(method, args[0], &block)
      end
    end
  end

  class Wrapper
    def initialize(stack, instance)
      @stack, @instance = stack, instance
    end

    def settings
      @instance.settings
    end

    def helpers
      @instance
    end

    def call(env)
      @stack.call(env)
    end

    def inspect
      "#<#{@instance.class} app_file=#{settings.app_file.inspect}>"
    end
  end

  delegate :get, :patch, :put, :post, :delete
  at_exit { Base.run! if $!.nil? && Base.run? }
end

extend Ramly