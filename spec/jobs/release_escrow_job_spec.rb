require 'rails_helper'

RSpec.describe ReleaseEscrowJob, type: :job do
  it "queues the job" do
    ActiveJob::Base.queue_adapter = :test
    expect { ReleaseEscrowJob.perform_later(1) }.to have_enqueued_job
  end
end