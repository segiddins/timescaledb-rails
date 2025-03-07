# frozen_string_literal: true

require 'timescaledb/rails/models/concerns/durationable'

module Timescaledb
  module Rails
    # :nodoc:
    class Hypertable < ::ActiveRecord::Base
      include Timescaledb::Rails::Models::Durationable

      self.table_name = 'timescaledb_information.hypertables'
      self.primary_key = 'hypertable_name'

      has_many :continuous_aggregates, foreign_key: 'hypertable_name',
                                       class_name: 'Timescaledb::Rails::ContinuousAggregate'
      has_many :compression_settings, foreign_key: 'hypertable_name',
                                      class_name: 'Timescaledb::Rails::CompressionSetting'
      has_many :dimensions, foreign_key: 'hypertable_name', class_name: 'Timescaledb::Rails::Dimension'
      has_many :jobs, foreign_key: 'hypertable_name', class_name: 'Timescaledb::Rails::Job'
      has_many :chunks, foreign_key: 'hypertable_name', class_name: 'Timescaledb::Rails::Chunk'

      # @return [String]
      def time_column_name
        time_dimension.column_name
      end

      # @return [String]
      def chunk_time_interval
        interval = time_dimension.time_interval

        interval.is_a?(String) ? interval : interval.inspect
      end

      # @return [ActiveRecord::Relation<CompressionSetting>]
      def compression_segment_settings
        compression_settings.segmentby_setting
      end

      # @return [ActiveRecord::Relation<CompressionSetting>]
      def compression_order_settings
        compression_settings.orderby_setting.where.not(attname: time_column_name)
      end

      # @return [String]
      def compression_policy_interval
        parse_duration(compression_job.config['compress_after'])
      end

      # @return [String]
      def reorder_policy_index_name
        reorder_job.config['index_name']
      end

      # @return [String]
      def retention_policy_interval
        parse_duration(retention_job.config['drop_after'])
      end

      # @return [Boolean]
      def compression_policy?
        compression_job.present?
      end

      # @return [Boolean]
      def compression?
        compression_settings.any?
      end

      # @return [Boolean]
      def reorder?
        reorder_job.present?
      end

      # @return [Boolean]
      def retention?
        retention_job.present?
      end

      private

      # @return [Job]
      def reorder_job
        @reorder_job ||= jobs.policy_reorder.first
      end

      # @return [Job]
      def retention_job
        @retention_job ||= jobs.policy_retention.first
      end

      # @return [Job]
      def compression_job
        @compression_job ||= jobs.policy_compression.first
      end

      # @return [Dimension]
      def time_dimension
        @time_dimension ||= dimensions.time.first
      end
    end
  end
end
