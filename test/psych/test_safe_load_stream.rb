# frozen_string_literal: true
require_relative 'helper'

module Psych
  class TestSafeLoadStream < TestCase
    class Foo; end

    def test_safe_load_stream_yields_documents
      list = []
      Psych.safe_load_stream("--- foo\n...\n--- bar") do |ruby|
        list << ruby
      end
      assert_equal %w{ foo bar }, list
    end

    def test_safe_load_stream_break
      list = []
      Psych.safe_load_stream("--- foo\n...\n--- `") do |ruby|
        list << ruby
        break
      end
      assert_equal %w{ foo }, list
    end

    def test_safe_load_stream_default_fallback
      assert_equal [], Psych.safe_load_stream("")
    end

    def test_safe_load_stream
      assert_equal [%w[a b], "foo"], Psych.safe_load_stream("- a\n- b\n--- foo")
    end

    def test_safe_load_raises_on_bad_input
      assert_raises(Psych::SyntaxError) { Psych.safe_load_stream("--- `") }
    end

    def test_symbol
      assert_raises(Psych::DisallowedClass) do
        assert_safe_cycle :foo, :bar
      end

      assert_raises(Psych::DisallowedClass) do
        Psych.safe_load_stream '--- !ruby/symbol foo', permitted_classes: []
      end

      assert_safe_cycle :foo, :bar, permitted_classes: [Symbol]
      assert_safe_cycle :foo, :bar, permitted_classes: %w{ Symbol }
      assert_equal [:foo], Psych.safe_load_stream('--- !ruby/symbol foo', permitted_classes: [Symbol])
    end

    def test_foo
      assert_raises(Psych::DisallowedClass) do
        Psych.safe_load_stream '--- !ruby/object:Foo {}', permitted_classes: [Foo]
      end

      assert_raises(Psych::DisallowedClass) do
        assert_safe_cycle [Foo.new]
      end

      doc = Psych.dump_stream(Foo.new, Foo.new)

      Psych.safe_load_stream(doc, permitted_classes: [Foo]) do |node|
        assert_kind_of(Foo, node)
      end
    end

    private

    def cycle *objects, permitted_classes: []
      Psych.safe_load_stream(Psych.dump_stream(*objects), permitted_classes: permitted_classes)
    end

    def assert_safe_cycle *objects, permitted_classes: []
      other = cycle *objects, permitted_classes: permitted_classes
      assert_equal objects, other
    end
  end
end
