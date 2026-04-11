module DbGuardFailures
  def self.unknown_db!(connection_summary)
    abort(
      "\n[CRITICAL ERROR] 无法识别当前连接的数据库名，已拒绝运行测试。\n\n" \
      "#{connection_summary}\n\n" \
      "修复建议：\n" \
      "- 确认你正在以 test 环境运行：RAILS_ENV=test\n" \
      "- 如本机设置了 DATABASE_URL（可能指向 development/staging），请取消该变量；或改用 TEST_DATABASE_URL 指向 test 数据库\n" \
      "- 然后执行：RAILS_ENV=test bin/rails db:prepare\n"
    )
  end

  def self.suspect_db_name!(db_name, connection_summary)
    abort(
      "\n[CRITICAL ERROR] 测试进程疑似连接到了非测试数据库（包含 production/development 关键字）：#{db_name}\n\n" \
      "#{connection_summary}\n\n" \
      "修复建议：\n" \
      "- 确认你正在以 test 环境运行：RAILS_ENV=test\n" \
      "- 如本机设置了 DATABASE_URL，请取消该变量；或改用 TEST_DATABASE_URL 指向 test 数据库\n" \
      "- 然后执行：RAILS_ENV=test bin/rails db:prepare\n"
    )
  end

  def self.non_test_db!(db_name, connection_summary)
    abort(
      "\n[CRITICAL ERROR] 测试进程尝试连接到非测试数据库：#{db_name}\n" \
      "要求：数据库名必须以 _test 结尾。\n\n" \
      "#{connection_summary}\n\n" \
      "修复建议：\n" \
      "- 检查 config/database.yml 的 test 配置（默认 cuhk_marketplace_test）\n" \
      "- 如本机设置了 DATABASE_URL，请取消该变量；或改用 TEST_DATABASE_URL 指向 test 数据库\n" \
      "- 然后执行：RAILS_ENV=test bin/rails db:prepare\n"
    )
  end

  def self.pending_migrations!(message)
    abort "\n[FATAL] 数据库迁移未同步：\n#{message}\n请执行 RAILS_ENV=test bin/rails db:prepare\n".strip
  end

  def self.connection_failed!(message, connection_summary)
    abort(
      "\n[FATAL] 测试数据库连接失败：#{message}\n\n" \
      "#{connection_summary}\n\n" \
      "修复建议：\n" \
      "- 启动本机/WSL 的 Postgres 服务\n" \
      "- 确认 config/database.yml 的 test 配置可连接（或设置 TEST_DATABASE_URL）\n" \
      "- 然后执行：RAILS_ENV=test bin/rails db:prepare\n"
    )
  end
end
