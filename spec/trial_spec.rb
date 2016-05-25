require 'spec_helper'
require 'trial'

describe Trial do
  include Trial

  let(:old_system) { double('old_system', :execute => 'old_system') }
  let(:new_system) { double('new_system', :execute => 'new_system') }
  let(:statsd) do
    double('statsd').tap do |statsd|
      allow(statsd).to receive(:increment).with(anything)
    end
  end
  let(:logger) do
    double('logger').tap do |logger|
      allow(logger).to receive(:info).with(anything)
    end
  end

  before do
    allow(statsd).to receive(:increment).with(anything)

    Trial.default_options[:statsd] = statsd
    Trial.default_options[:logger] = logger
  end

  describe '#attempt' do

    it 'raises an error if a try block is not provided' do
      expect {
        attempt('attempt_name') do |attempt|
        end
      }.to raise_error('attempt requires a try block')
    end

    it 'raises an error if you do not provide it a block' do
      expect {
        attempt('attempt_name')
      }.to raise_error('attempt requires an attempt block')
    end

    it 'accepts a statsd for tracking' do
      our_statsd = double('fake_statsd')
      allow(our_statsd).to receive(:increment).with(anything)

      attempt('attempt_name', :statsd => our_statsd) do |attempt|
        attempt.try do
          new_system.execute
        end
      end

      expect(our_statsd).to have_received(:increment).with('trial.attempt_name.try.success')
    end

    it 'accepts a logger for error reporting' do
      our_logger = double('fake_logger')
      allow(our_logger).to receive(:info).with(anything)
      allow(new_system).to receive(:execute).and_raise('Uh oh!')
      attempt('attempt_name', :logger => our_logger) do |attempt|
        attempt.try do
          new_system.execute
        end
      end

      expect(our_logger).to have_received(:info).with(
        hash_including(:message => 'trial.attempt_name.try.error')
      )
    end


    it 'attempts the try block and skips the fallback if successful' do
      result = attempt('attempt_name') do |attempt|
        attempt.try do
          new_system.execute
        end

        attempt.fallback do
          old_system.execute
        end
      end

      expect(result).to eq('new_system')
      expect(new_system).to have_received(:execute)
      expect(old_system).not_to have_received(:execute)
      expect(statsd).to have_received(:increment).with('trial.attempt_name.try.success')
      expect(statsd).to have_received(:increment).with('trial.attempt_name.fallback.skipped')
    end

    it 'attempts the try block and uses the fallback if a failure occurs' do
      allow(new_system).to receive(:execute).and_raise('Uh oh!')

      result = attempt('attempt_name') do |attempt|
        attempt.try do
          new_system.execute
        end

        attempt.fallback do
          old_system.execute
        end
      end

      expect(result).to eq('old_system')
      expect(new_system).to have_received(:execute)
      expect(old_system).to have_received(:execute)
      expect(statsd).to have_received(:increment).with('trial.attempt_name.try.error')
      expect(statsd).to have_received(:increment).with('trial.attempt_name.fallback.success')
    end

    it 'evaluates the run_if block to determine whether or not to run the attempt' do
      fake_toggle = double('fake_toggle', :run? => true)

      result = attempt('attempt_name') do |attempt|
        attempt.run_if { fake_toggle.run? }

        attempt.try do
          new_system.execute
        end

        attempt.fallback do
          old_system.execute
        end
      end

      expect(fake_toggle).to have_received(:run?)
      expect(new_system).to have_received(:execute)
      expect(old_system).not_to have_received(:execute)
    end

    it 'skips the try block and just uses the fallback if the run_if evaluates false' do
      result = attempt('attempt_name') do |attempt|
        attempt.run_if { false }

        attempt.try do
          new_system.execute
        end

        attempt.fallback do
          old_system.execute
        end
      end

      expect(result).to eq('old_system')
      expect(new_system).not_to have_received(:execute)
      expect(old_system).to have_received(:execute)
      expect(statsd).to have_received(:increment).with('trial.attempt_name.try.skipped')
      expect(statsd).to have_received(:increment).with('trial.attempt_name.fallback.success')
    end

    it 'evaluates to nil upon attempt failure if no fallback is provided' do
      allow(new_system).to receive(:execute).and_raise('Uh oh!')
      result = attempt('attempt_name') do |attempt|
        attempt.try do
          new_system.execute
        end
      end

      expect(result).to be nil
    end

    it 'resurfaces errors from the fallback' do
      allow(new_system).to receive(:execute).and_raise('Uh oh!')
      allow(old_system).to receive(:execute).and_raise('Failsafe failed!')

      expect {
        attempt('attempt_name') do |attempt|
          attempt.try { new_system.execute }
          attempt.fallback { old_system.execute }
        end
      }.to raise_error('Failsafe failed!')

      expect(statsd).to have_received(:increment).with('trial.attempt_name.try.error')
      expect(statsd).to have_received(:increment).with('trial.attempt_name.fallback.error')

      expect(logger).to have_received(:info).with(
        hash_including(
          :message => 'trial.attempt_name.try.error',
          :exception => RuntimeError,
          :error_message => 'Uh oh!',
          :backtrace => instance_of(Array)
        )
      )

      expect(logger).to have_received(:info).with(
        hash_including(
          :message => 'trial.attempt_name.fallback.error',
          :exception => RuntimeError,
          :error_message => 'Failsafe failed!',
          :backtrace => instance_of(Array)
        )
      )
    end
  end
end
