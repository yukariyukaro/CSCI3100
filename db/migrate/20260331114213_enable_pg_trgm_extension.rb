class EnablePgTrgmExtension < ActiveRecord::Migration[7.2]
  def up
    enable_extension 'pg_trgm' rescue nil
  end

  def down
    disable_extension 'pg_trgm' rescue nil
  end
end
