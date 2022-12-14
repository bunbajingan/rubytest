# frozen_string_literal: true
require_relative 'helper'

module Psych
  class TestMergeKeys < TestCase
    class Product
      attr_reader :bar
    end

    def test_merge_key_with_bare_hash
      doc = Psych.load <<-eodoc
map:
  <<:
    hello: world
      eodoc
      hash = { "map" => { "hello" => "world" } }
      assert_equal hash, doc
    end

    def test_merge_key_with_bare_hash_symbolized_names
      doc = Psych.load <<-eodoc, symbolize_names: true
map:
  <<:
    hello: world
      eodoc
      hash = { map: { hello: "world" } }
      assert_equal hash, doc
    end

    def test_roundtrip_with_chevron_key
      h = {}
      v = { 'a' => h, '<<' => h }
      assert_cycle v
    end

    def test_explicit_string
      doc = Psych.unsafe_load <<-eoyml
a: &me { hello: world }
b: { !!str '<<': *me }
eoyml
      expected = {
        "a" => { "hello" => "world" },
        "b" => {
          "<<" => { "hello" => "world" }
        }
      }
      assert_equal expected, doc
    end

    def test_mergekey_with_object
      s = <<-eoyml
foo: &foo
  bar: 10
product:
  !ruby/object:#{Product.name}
  <<: *foo
      eoyml
      hash = Psych.unsafe_load s
      assert_equal({"bar" => 10}, hash["foo"])
      product = hash["product"]
      assert_equal 10, product.bar
    end

    def test_merge_nil
      yaml = <<-eoyml
defaults: &defaults
development:
  <<: *defaults
      eoyml
      assert_equal({'<<' => nil }, Psych.unsafe_load(yaml)['development'])
    end

    def test_merge_array
      yaml = <<-eoyml
foo: &hello
- 1
baz:
  <<: *hello
      eoyml
      assert_equal({'<<' => [1]}, Psych.unsafe_load(yaml)['baz'])
    end

    def test_merge_is_not_partial
      yaml = <<-eoyml
default: &default
  hello: world
foo: &hello
- 1
baz:
  <<: [*hello, *default]
      eoyml
      doc = Psych.unsafe_load yaml
      refute doc['baz'].key? 'hello'
      assert_equal({'<<' => [[1], {"hello"=>"world"}]}, Psych.unsafe_load(yaml)['baz'])
    end

    def test_merge_seq_nil
      yaml = <<-eoyml
foo: &hello
baz:
  <<: [*hello]
      eoyml
      assert_equal({'<<' => [nil]}, Psych.unsafe_load(yaml)['baz'])
    end

    def test_bad_seq_merge
      yaml = <<-eoyml
defaults: &defaults [1, 2, 3]
development:
  <<: *defaults
      eoyml
      assert_equal({'<<' => [1,2,3]}, Psych.unsafe_load(yaml)['development'])
    end

    def test_missing_merge_key
      yaml = <<-eoyml
bar:
  << : *foo
      eoyml
      exp = assert_raise(Psych::AnchorNotDefined) { Psych.load(yaml, aliases: true) }
      assert_match 'foo', exp.message
    end

    # [ruby-core:34679]
    def test_merge_key
      yaml = <<-eoyml
foo: &foo
  hello: world
bar:
  << : *foo
  baz: boo
      eoyml

      hash = {
        "foo" => { "hello" => "world"},
        "bar" => { "hello" => "world", "baz" => "boo" } }
      assert_equal hash, Psych.unsafe_load(yaml)
    end

    def test_multiple_maps
      yaml = <<-eoyaml
---
- &CENTER { x: 1, y: 2 }
- &LEFT { x: 0, y: 2 }
- &BIG { r: 10 }
- &SMALL { r: 1 }

# All the following maps are equal:

- # Merge multiple maps
  << : [ *CENTER, *BIG ]
  label: center/big
      eoyaml

      hash = {
        'x' => 1,
        'y' => 2,
        'r' => 10,
        'label' => 'center/big'
      }

      assert_equal hash, Psych.unsafe_load(yaml)[4]
    end

    def test_override
      yaml = <<-eoyaml
---
- &CENTER { x: 1, y: 2 }
- &LEFT { x: 0, y: 2 }
- &BIG { r: 10 }
- &SMALL { r: 1 }

# All the following maps are equal:

- # Override
  << : [ *BIG, *LEFT, *SMALL ]
  x: 1
  label: center/big
      eoyaml

      hash = {
        'x' => 1,
        'y' => 2,
        'r' => 10,
        'label' => 'center/big'
      }

      assert_equal hash, Psych.unsafe_load(yaml)[4]
    end
  end
end
