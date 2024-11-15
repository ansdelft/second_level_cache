# frozen_string_literal: true

module SecondLevelCache
  module Mixin
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :second_level_cache_options

      delegate :logger, :cache_store, :cache_key_prefix, to: SecondLevelCache

      def second_level_cache(options = {})
        @second_level_cache_enabled = true
        @second_level_cache_options = options
        @second_level_cache_options[:version] ||= 0
        @second_level_cache_options[:expires_in] ||= 1.week
        relation.class.send :prepend, SecondLevelCache::ActiveRecord::FinderMethods
        prepend SecondLevelCache::ActiveRecord::Core
      end

      def second_level_cache_enabled?
        if defined? @second_level_cache_enabled
          @second_level_cache_enabled == true && SecondLevelCache.cache_enabled?
        else
          false
        end
      end

      def without_second_level_cache(&blk)
        SecondLevelCache.without_second_level_cache(&blk) if blk
      end

      # Get MD5 digest of this Model schema
      # http://api.rubyonrails.org/classes/ActiveRecord/Core/ClassMethods.html#method-i-inspect
      def cache_version
        return @cache_version if defined? @cache_version
        # This line is copy from:
        # https://github.com/rails/rails/blob/f9a5f48/activerecord/lib/active_record/core.rb#L236
        attr_list = attribute_types.map { |name, type| "#{name}: #{type.type}" } * ", "
        model_schema_digest = Digest::MD5.hexdigest(attr_list)
        @cache_version = "#{second_level_cache_options[:version]}/#{model_schema_digest}"
      end

      def second_level_cache_key(id)
        "#{cache_key_prefix}/#{table_name.downcase}/#{id}/#{cache_version}"
      end

      def read_second_level_cache(id)
        return unless second_level_cache_enabled?
        RecordMarshal.load(SecondLevelCache.cache_store.read(second_level_cache_key(id)))
      end

      def expire_second_level_cache(id)
        return unless second_level_cache_enabled?
        SecondLevelCache.cache_store.delete(second_level_cache_key(id))
      end
    end

    def second_level_cache_key
      base_klass.second_level_cache_key(id)
    end

    def base_klass
      self.class.base_class
    end

    def expire_second_level_cache
      return unless base_klass.second_level_cache_enabled?

      SecondLevelCache.cache_store.delete(second_level_cache_key)
    end

    def write_second_level_cache
      return unless base_klass.second_level_cache_enabled?

      marshal = RecordMarshal.dump(self)
      expires_in = base_klass.second_level_cache_options[:expires_in]
      SecondLevelCache.cache_store.write(second_level_cache_key, marshal, expires_in: expires_in)
    end

    alias_method :update_second_level_cache, :write_second_level_cache
  end
end
