# frozen_string_literal: true
require_relative 'helper'

module Psych
  class Tagged
    yaml_tag '!foo'

    attr_accessor :baz

    def initialize
      @baz = 'bar'
    end
  end

  class Foo
    attr_accessor :parent

    def initialize parent
      @parent = parent
    end
  end

  class TestObject < TestCase
    def test_dump_with_tag
      tag = Tagged.new
      assert_match('foo', Psych.dump(tag))
    end

    def test_tag_round_trip
      tag   = Tagged.new
      tag2  = Psych.unsafe_load(Psych.dump(tag))
      assert_equal tag.baz, tag2.baz
      assert_instance_of(Tagged, tag2)
    end

    def test_cyclic_references
      foo = Foo.new(nil)
      foo.parent = foo
      loaded = Psych.load(Psych.dump(foo), permitted_classes: [Foo], aliases: true)

      assert_instance_of(Foo, loaded)
      assert_same loaded, loaded.parent
    end

    def test_cyclic_reference_uses_alias
      foo = Foo.new(nil)
      foo.parent = foo

      assert_raise(AliasesNotEnabled) do
        Psych.load(Psych.dump(foo), permitted_classes: [Foo], aliases: false)
      end
    end
  end
end
