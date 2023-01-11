# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecord::Migration::CommandRecorder do # rubocop:disable RSpec/FilePath
  let(:connection) { ActiveRecord::Base.connection }
  let(:recorder)   { described_class.new(connection) }

  describe '.revert' do
    context 'when create_hypertable' do
      context 'when given a block' do
        it 'returns drop_table' do
          block = -> {}

          create_hypertable_inverse = recorder.inverse_of(:create_hypertable, %i[events created_at], &block)

          expect(create_hypertable_inverse).to eq([:drop_table, :events, block])
        end
      end

      context 'when given no block' do
        it 'raises IrreversibleMigration error' do
          expect do
            recorder.inverse_of(:create_hypertable, %i[events created_at])
          end.to raise_error(ActiveRecord::IrreversibleMigration)
        end
      end
    end

    context 'when add_hypertable_compression' do
      let(:params) { [:events, 20.days, { order_by: :name, segment_by: :created_at }] }

      it 'returns remove_hypertable_compression' do
        add_hypertable_compression_inverse = recorder.inverse_of(:add_hypertable_compression, params)

        expect(add_hypertable_compression_inverse).to eq([:remove_hypertable_compression, params, nil])
      end
    end

    context 'when remove_hypertable_compression' do
      context 'when given table name and compress after' do
        let(:params) { [:events, 20.days, { segment_by: :created_at, order_by: :name }] }

        it 'returns add_hypertable_compression' do
          remove_hypertable_compression_inverse = recorder.inverse_of(:remove_hypertable_compression, params)

          expect(remove_hypertable_compression_inverse).to eq([:add_hypertable_compression, params, nil])
        end
      end

      context 'when given only table name' do
        it 'raises IrreversibleMigration error' do
          expect do
            recorder.inverse_of(:remove_hypertable_compression, %i[events])
          end.to raise_error(ActiveRecord::IrreversibleMigration)
        end
      end
    end

    context 'when add_hypertable_retention_policy' do
      let(:params) { [:events, 1.year, { order_by: :name, segment_by: :created_at }] }

      it 'returns remove_hypertable_retention_policy' do
        add_hypertable_retention_policy_inverse = recorder.inverse_of(:add_hypertable_retention_policy, params)

        expect(add_hypertable_retention_policy_inverse).to eq([:remove_hypertable_retention_policy, params, nil])
      end
    end

    context 'when remove_hypertable_retention_policy' do
      context 'when given table name and compress after' do
        let(:params) { [:events, 1.year, { segment_by: :created_at, order_by: :name }] }

        it 'returns add_hypertable_retention_policy' do
          remove_hypertable_retention_policy_inverse = recorder.inverse_of(:remove_hypertable_retention_policy, params)

          expect(remove_hypertable_retention_policy_inverse).to eq([:add_hypertable_retention_policy, params, nil])
        end
      end

      context 'when given only table name' do
        it 'raises IrreversibleMigration error' do
          expect do
            recorder.inverse_of(:remove_hypertable_retention_policy, %i[events])
          end.to raise_error(ActiveRecord::IrreversibleMigration)
        end
      end
    end

    context 'when add_hypertable_reorder_policy' do
      let(:params) { %i[events index_events_on_created_at_and_name] }

      it 'returns remove_hypertable_reorder_policy' do
        add_hypertable_reorder_policy_inverse = recorder.inverse_of(:add_hypertable_reorder_policy, params)

        expect(add_hypertable_reorder_policy_inverse).to eq([:remove_hypertable_reorder_policy, params, nil])
      end
    end

    context 'when remove_hypertable_reorder_policy' do
      context 'when given table name and index name' do
        let(:params) { %i[events index_events_on_created_at_and_name] }

        it 'returns add_hypertable_reorder_policy' do
          remove_hypertable_reorder_policy_inverse = recorder.inverse_of(:remove_hypertable_reorder_policy, params)

          expect(remove_hypertable_reorder_policy_inverse).to eq([:add_hypertable_reorder_policy, params, nil])
        end
      end

      context 'when given only table name' do
        it 'raises IrreversibleMigration error' do
          expect do
            recorder.inverse_of(:remove_hypertable_reorder_policy, %i[events])
          end.to raise_error(ActiveRecord::IrreversibleMigration)
        end
      end
    end

    context 'when create_continuous_aggregate' do
      let(:params) { [:temperature_events, Event.time_bucket(1.day).avg(:value).temperature.to_sql] }

      it 'returns drop_continuous_aggregate' do
        create_continuous_aggregate_inverse = recorder.inverse_of(:create_continuous_aggregate, params)

        expect(create_continuous_aggregate_inverse).to eq([:drop_continuous_aggregate, params, nil])
      end
    end

    context 'when drop_continuous_aggregate' do
      context 'when given view name and view query' do
        let(:params) { [:temperature_events, Event.time_bucket(1.day).avg(:value).temperature.to_sql] }

        it 'returns create_continuous_aggregate' do
          drop_continuous_aggregate_inverse = recorder.inverse_of(:drop_continuous_aggregate, params)

          expect(drop_continuous_aggregate_inverse).to eq([:create_continuous_aggregate, params, nil])
        end
      end

      context 'when given only view name' do
        it 'raises IrreversibleMigration error' do
          expect do
            recorder.inverse_of(:drop_continuous_aggregate, %i[temperature_events])
          end.to raise_error(ActiveRecord::IrreversibleMigration)
        end
      end
    end
  end
end
