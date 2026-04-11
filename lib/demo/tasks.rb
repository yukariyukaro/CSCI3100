require_relative "tasks/cable"
require_relative "tasks/chat"
require_relative "tasks/cleanup"
require_relative "tasks/payments"
require_relative "tasks/products"
require_relative "tasks/scenario"
require_relative "tasks/scope"
require_relative "tasks/users"

module Demo
  module Tasks
    DEMO_EMAILS = %w[
      demo_user@example.com
      demo_seller@example.com
      demo_buyer@example.com
    ].freeze

    PRODUCT_DEFINITIONS = {
      active: {
        name: "[DEMO] 可预定商品",
        description: "用于演示 active -> reserve 的商品（可被买家预定）",
        price: 199.0,
        condition: "9成新"
      },
      pending: {
        name: "[DEMO] 已预定商品",
        description: "用于演示 pending（已有进行中交易）与 fake 支付流程",
        price: 299.0,
        condition: "8成新"
      },
      sold: {
        name: "[DEMO] 已售出商品",
        description: "用于演示 sold（已完成交易）",
        price: 399.0,
        condition: "7成新"
      },
      abnormal_payment: {
        name: "[DEMO] 异常支付商品",
        description: "用于演示 manual_intervention_required 的支付记录",
        price: 499.0,
        condition: "全新"
      }
    }.freeze

    def self.seed!
      Scenario.ensure!
      Rails.logger.debug "demo:seed 完成"
    end

    def self.reset!
      Rails.logger.debug "demo:reset 将清理 demo 场景数据（users/products/transactions/payments/conversations/messages）"
      Cleanup.deep_cleanup!
      Cable.clear_prefix_if_enabled!
      Scenario.ensure!
      Rails.logger.debug "demo:reset 完成"
      Rails.logger.debug "demo:reset 完成。若浏览器正在打开聊天页面，请刷新或重新进入会话以重新同步。"
    end

    def self.reset_chat!
      Chat.reset!
      Rails.logger.debug "demo:reset_chat 完成"
    end

    def self.prepare_payment!
      Payments.prepare!
      Rails.logger.debug "demo:prepare_payment 完成"
    end
  end
end
