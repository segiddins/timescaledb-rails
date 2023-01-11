# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecord::Tasks::DatabaseTasks do # rubocop:disable RSpec/FilePath
  after { database_delete_structure_file! }

  describe '.dump_schema' do
    before { ENV['SCHEMA'] = database_structure_name }

    context 'when :sql format' do
      it 'does not include _timescaledb_internal tables' do
        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).not_to include('_timescaledb_internal.compressed_data')
      end

      it 'includes ts_insert_blocker drop statements' do
        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).to include('DROP TRIGGER IF EXISTS ts_insert_blocker ON events;')
      end

      it 'includes create_hypertable statements' do
        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).to include("SELECT create_hypertable('events', 'created_at', if_not_exists => 'TRUE', chunk_time_interval => INTERVAL '2 days');") # rubocop:disable Layout/LineLength
      end

      it 'includes compression ALTER TABLE statements' do
        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).to include("ALTER TABLE events SET (timescaledb.compress, timescaledb.compress_segmentby = 'event_type_id, name', timescaledb.compress_orderby = 'occurred_at ASC, recorded_at DESC');") # rubocop:disable Layout/LineLength
      end

      it 'includes add_compression_policy statements' do
        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).to include("SELECT add_compression_policy('events', INTERVAL '20 days');")
      end

      it 'includes add_reorder_policy statements' do
        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).to include("SELECT add_reorder_policy('events', 'index_events_on_created_at_and_name');") # rubocop:disable Layout/LineLength
      end

      it 'includes add_retention_policy statements' do
        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).to include("SELECT add_retention_policy('events', INTERVAL '1 year');")
      end

      it 'includes create_continuous_aggregate statements' do # rubocop:disable RSpec/ExampleLength
        interval = Rails.version.to_i >= 7 ? 'P1D' : '1 day'

        described_class.dump_schema(database_configuration, :sql)

        expect(database_structure).to include(
          <<~SQL
            CREATE MATERIALIZED VIEW temperature_events WITH (timescaledb.continuous) AS
              SELECT time_bucket('#{interval}'::interval, events.created_at) AS time_bucket,
                  avg(events.value) AS avg
                 FROM events
                WHERE ((events.event_type)::text = 'temperature'::text)
                GROUP BY (time_bucket('#{interval}'::interval, events.created_at))
                ORDER BY (time_bucket('#{interval}'::interval, events.created_at));
          SQL
        )
      end
    end

    context 'when :ruby format' do
      it 'includes create_hypertable statements' do
        described_class.dump_schema(database_configuration, :ruby)

        expect(database_structure).to include('create_hypertable "events", "created_at", chunk_time_interval: "2 days"')
      end

      it 'includes add_hypertable_compression statements' do
        described_class.dump_schema(database_configuration, :ruby)

        expect(database_structure).to include('add_hypertable_compression "events", "20 days", segment_by: "event_type_id, name", order_by: "occurred_at ASC, recorded_at DESC"') # rubocop:disable Layout/LineLength
      end

      it 'includes add_hypertable_reorder_policy statements' do
        described_class.dump_schema(database_configuration, :ruby)

        expect(database_structure).to include('add_hypertable_reorder_policy "events", "index_events_on_created_at_and_name"') # rubocop:disable Layout/LineLength
      end

      it 'includes add_hypertable_retention_policy statements' do
        described_class.dump_schema(database_configuration, :ruby)

        expect(database_structure).to include('add_hypertable_retention_policy "events", "1 year"')
      end

      it 'includes create_continuous_aggregate statements' do # rubocop:disable RSpec/ExampleLength
        interval = Rails.version.to_i >= 7 ? 'P1D' : '1 day'

        described_class.dump_schema(database_configuration, :ruby)

        expect(database_structure).to include(
          <<-QUERY
  create_continuous_aggregate "temperature_events", <<-SQL
    SELECT time_bucket('#{interval}'::interval, events.created_at) AS time_bucket,
      avg(events.value) AS avg
     FROM events
    WHERE ((events.event_type)::text = 'temperature'::text)
    GROUP BY (time_bucket('#{interval}'::interval, events.created_at))
    ORDER BY (time_bucket('#{interval}'::interval, events.created_at));
  SQL
          QUERY
        )
      end
    end
  end
end
