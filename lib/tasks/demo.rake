require "demo/tasks"

namespace :demo do
  desc "非破坏性：补齐 demo 演示数据（用户/商品/聊天/支付）"
  task seed: :environment do
    Demo::Tasks.seed!
  end

  desc "显式破坏性：仅清理 demo 场景数据后重建演示数据"
  task reset: :environment do
    Demo::Tasks.reset!
  end

  desc "仅重置 demo 聊天数据（conversations/messages）"
  task reset_chat: :environment do
    Demo::Tasks.reset_chat!
  end

  desc "准备 demo 支付数据（pending + optional 异常支付记录）"
  task prepare_payment: :environment do
    Demo::Tasks.prepare_payment!
  end
end
