require "demo/tasks"

namespace :demo do
  desc "非破坏性：补齐 demo 演示数据（用户/商品/聊天/支付）"
  task(seed: :environment) { Demo::Tasks.seed! }

  desc "显式破坏性：仅清理 demo 场景数据后重建演示数据"
  task(reset: :environment) { Demo::Tasks.reset! }

  desc "显式破坏性：覆盖式恢复 demo 头像/商品图片等资源（会 purge 旧附件）"
  task(restore_assets: :environment) { Demo::Tasks.restore_assets! }

  desc "仅重置 demo 聊天数据（conversations/messages）"
  task(reset_chat: :environment) { Demo::Tasks.reset_chat! }

  desc "准备 demo 支付数据（pending + optional 异常支付记录）"
  task(prepare_payment: :environment) { Demo::Tasks.prepare_payment! }

  desc "非生产环境：清理未被任何 Attachment 引用的 ActiveStorage blobs（DRY_RUN=1 可预览数量）"
  task purge_unattached_blobs: :environment do
    dry_run = ENV["DRY_RUN"].to_s == "1"
    count = Demo::Tasks.purge_unattached_blobs!(dry_run: dry_run)
    puts "purge_unattached_blobs count=#{count} dry_run=#{dry_run}"
  end
end
