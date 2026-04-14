module Payments
  class WebhookProcessor
    def self.call(request:, provider:)
      new(request, provider).call
    end

    def initialize(request, provider)
      @request = request
      @provider = provider
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def call
      payload = @provider.verify_webhook(@request)
      event_id = payload.fetch("event_id")

      PaymentWebhookEvent.transaction do
        event = lock_and_find_or_create_event(event_id)

        return :ok if event.processed_at.present?

        payment = Payment.lock.find_by!(
          provider: @provider.name,
          provider_reference: @provider.extract_reference(payload)
        )

        authorize!(payment, payload)

        response = if webhook_cancelled?(payload)
                     cancel!(payment)
                     respond_for_cancel(payment)
                   else
                     settle!(payment, payload)
                     respond_for_success(payment)
                   end

        event.update!(payment_id: payment.id, processed_at: Time.current)
        response
      end
    rescue ActiveRecord::RecordNotFound
      :not_found
    rescue KeyError, JSON::ParserError, Stripe::SignatureVerificationError
      :bad_request
    rescue StandardError => e
      log_error(e, payload)
      :internal_server_error
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def respond_for_cancel(payment)
      if @provider.name == "fake"
        { redirect: Rails.application.routes.url_helpers.product_path(payment.product_transaction.product),
          alert: I18n.t("payments.cancelled") }
      else
        :ok
      end
    end

    def respond_for_success(payment)
      if @provider.name == "fake"
        { redirect: Rails.application.routes.url_helpers.product_path(payment.product_transaction.product),
          notice: I18n.t("payments.success") }
      else
        :ok
      end
    end

    def lock_and_find_or_create_event(event_id)
      PaymentWebhookEvent.lock("FOR UPDATE").find_or_create_by!(
        provider: @provider.name,
        event_id: event_id
      )
    rescue ActiveRecord::RecordNotUnique
      PaymentWebhookEvent.lock("FOR UPDATE").find_by!(
        provider: @provider.name,
        event_id: event_id
      )
    end

    def authorize!(payment, payload)
      @provider.authorize_webhook!(payment, payload)
    end

    def webhook_cancelled?(payload)
      payload.fetch("outcome", "succeeded").to_s == "cancelled"
    end

    def cancel!(payment)
      return if payment.succeeded? || payment.cancelled?

      payment.update!(status: :cancelled)
    end

    def settle!(payment, payload)
      provider_amount = extract_amount(payload)
      PaymentSettlement.call(payment, provider_amount: provider_amount)
    end

    def extract_amount(payload)
      @provider.extract_amount(payload)
    end

    def log_error(error, payload)
      event_id = payload&.dig("event_id") || "unknown"
      reference = payload&.dig("provider_reference") || "unknown"
      event_type = payload&.dig("type") || "unknown"

      Rails.logger.error(
        "[WebhookProcessor] Unexpected error: #{error.class} - #{error.message} " \
        "| provider=#{@provider.name} event_id=#{event_id} type=#{event_type} reference=#{reference}"
      )
      Rails.logger.error(error.backtrace.join("\n")) if error.backtrace
    end
  end
end
