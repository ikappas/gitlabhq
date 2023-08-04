# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::StandardContext do
  let(:snowplow_context) { subject.to_context }

  describe '#to_context' do
    context 'environment' do
      shared_examples 'contains environment' do |expected_environment|
        it 'contains environment' do
          expect(snowplow_context.to_json.dig(:data, :environment)).to eq(expected_environment)
        end
      end

      context 'development or test' do
        include_examples 'contains environment', 'development'
      end

      context 'staging' do
        before do
          stub_config_setting(url: Gitlab::Saas.staging_com_url)
        end

        include_examples 'contains environment', 'staging'
      end

      context 'production' do
        before do
          stub_config_setting(url: Gitlab::Saas.com_url)
        end

        include_examples 'contains environment', 'production'
      end

      context 'org' do
        before do
          stub_config_setting(url: Gitlab::Saas.dev_url)
        end

        include_examples 'contains environment', 'org'
      end

      context 'other self-managed instance' do
        before do
          stub_rails_env('production')
        end

        include_examples 'contains environment', 'self-managed'
      end
    end

    it 'contains source' do
      expect(snowplow_context.to_json.dig(:data, :source)).to eq(described_class::GITLAB_RAILS_SOURCE)
    end

    it 'contains context_generated_at timestamp', :freeze_time do
      expect(snowplow_context.to_json.dig(:data, :context_generated_at)).to eq(Time.current)
    end

    it 'contains standard properties' do
      standard_properties = [:user_id, :project_id, :namespace_id, :plan]
      expect(snowplow_context.to_json[:data].keys).to include(*standard_properties)
    end

    context 'with standard properties' do
      let(:user_id) { 1 }
      let(:project_id) { 2 }
      let(:namespace_id) { 3 }
      let(:plan_name) { "plan name" }

      subject do
        described_class.new(user_id: user_id, project_id: project_id, namespace_id: namespace_id, plan_name: plan_name)
      end

      it 'holds the correct values', :aggregate_failures do
        json_data = snowplow_context.to_json.fetch(:data)
        expect(json_data[:user_id]).to eq(user_id)
        expect(json_data[:project_id]).to eq(project_id)
        expect(json_data[:namespace_id]).to eq(namespace_id)
        expect(json_data[:plan]).to eq(plan_name)
      end
    end

    context 'with extra data' do
      subject { described_class.new(extra_key_1: 'extra value 1', extra_key_2: 'extra value 2') }

      it 'includes extra data in `extra` hash' do
        expect(snowplow_context.to_json.dig(:data, :extra)).to eq(extra_key_1: 'extra value 1', extra_key_2: 'extra value 2')
      end
    end

    context 'without extra data' do
      it 'contains an empty `extra` hash' do
        expect(snowplow_context.to_json.dig(:data, :extra)).to be_empty
      end
    end

    context 'with incorrect argument type' do
      subject { described_class.new(project_id: "a string") }

      it 'does call `track_and_raise_for_dev_exception`' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        snowplow_context
      end
    end
  end
end
