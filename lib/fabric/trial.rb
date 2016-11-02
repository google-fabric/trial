module Fabric
  module Trial

    def self.default_options
      @default_options ||= {}
    end

    class Attempt
      attr_accessor :name, :statsd, :logger

      def initialize(name, options = {})
        self.name = name
        self.statsd = options[:statsd] || Trial.default_options[:statsd]
        self.logger = options[:logger] || Trial.default_options[:logger]
      end

      def run_if(&block)
        @_run_if = block
      end

      def try(&block)
        @_attempt_try = block
      end

      def fallback(&block)
        @_fallback = block
      end

      def run
        raise 'attempt requires a try block' unless @_attempt_try

        run_fallback = false
        result = nil
        begin
          if should_run_attempt?
            result = @_attempt_try.call
            tick('try.success')
          else
            tick('try.skipped')
            run_fallback = true
          end
        rescue StandardError => e
          record_error_information('try', e)
          run_fallback = true
        end
        if run_fallback
          if @_fallback
            begin
              result = @_fallback.call
              tick('fallback.success')
            rescue StandardError => e
              record_error_information('fallback', e)
              raise e
            end
          else
            result = nil
          end
        else
          tick('fallback.skipped')
        end

        result
      end

      protected

      def record_error_information(scope, error)
        measurement_scope = "#{scope}.error"
        tick(measurement_scope)
        message_payload = {
          :message => scoped_metric(measurement_scope),
          :exception => error.class,
          :error_message => error.message,
          :backtrace => error.backtrace.take(5)
        }
        log(message_payload)
      end

      def log(message_hash)
        if logger
          logger.info(message_hash)
        end
      end

      def tick(metric)
        if statsd
          statsd.increment(scoped_metric(metric))
        end
      end

      def scoped_metric(metric_name)
        "trial.#{name}.#{metric_name}"
      end

      private

      def should_run_attempt?
        if @_run_if
          @_run_if.call
        else
          true
        end
      end

    end

    def attempt(name, options = {})
      raise 'attempt requires an attempt block' unless block_given?
      attempt = Attempt.new(name, options)
      yield attempt
      attempt.run
    end
  end
end
