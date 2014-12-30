module Sails
  class LogSubscriber < ActiveSupport::LogSubscriber
    INTERNAL_PARAMS = %w(controller action format _method only_path)

    def start_processing(event)
      return unless logger.info?

      payload = event.payload
      params = payload[:params]

      info ""
      info "Processing by #{payload[:controller]}##{payload[:action]} at #{Time.now}"
      info "  Parameters: #{params.inspect}" unless params.empty?

      ActiveRecord::LogSubscriber.reset_runtime if defined?(ActiveRecord::LogSubscriber)
    end

    def process_action(event)
      info do
        payload   = event.payload
        additions = []

        additions << ("DB: %.1fms" % payload[:db_runtime].to_f) if payload[:db_runtime]
        additions << ("Views: %.1fms" % payload[:view_runtime].to_f) if payload[:view_runtime]
        status = payload[:status]
        payload[:runtime] = event.duration

        message = "Completed #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]} in #{event.duration.round(2)}ms"
        message << " (#{additions.join(" | ")})"
        message
      end
    end

    def logger
      Sails.logger
    end
  end
end

Sails::LogSubscriber.attach_to :sails
