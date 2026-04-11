module TestData
  @mutex = Mutex.new
  @seq = 0

  def self.next_seq
    @mutex.synchronize do
      @seq += 1
    end
  end

  def self.unique_email(prefix: "user")
    n = next_seq
    "test-#{prefix}-#{Process.pid}-#{n}@example.com"
  end
end
