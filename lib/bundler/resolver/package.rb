# frozen_string_literal: true

module Bundler
  class Resolver
    #
    # Represents a gem being resolved, in a format PubGrub likes.
    #
    # The class holds the following information:
    #
    # * Platforms this gem will be resolved on.
    # * The locked version of this gem resolution should favor (if any).
    # * Whether the gem should be unlocked to its latest version.
    # * The dependency explicit set in the Gemfile for this gem (if any).
    #
    class Package
      attr_reader :name, :platforms, :dependency

      def initialize(name, platforms, locked_specs, unlock, dependency: nil)
        @name = name
        @platforms = platforms
        @locked_specs = locked_specs
        @unlock = unlock
        @dependency = dependency
      end

      def to_s
        @name.delete("\0")
      end

      def root?
        false
      end

      def meta?
        @name.end_with?("\0")
      end

      def ==(other)
        self.class == other.class && @name == other.name
      end

      def hash
        @name.hash
      end

      def locked_version
        @locked_specs[name].first&.version
      end

      def unlock?
        @unlock.empty? || @unlock.include?(name)
      end

      def prerelease_specified?
        @dependency&.prerelease?
      end

      def force_ruby_platform?
        @dependency&.force_ruby_platform
      end

      def current_platform?
        @dependency&.current_platform?
      end
    end
  end
end
