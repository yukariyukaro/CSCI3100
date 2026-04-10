require 'rails_helper'

RSpec.describe ExpireListingJob, type: :job do
  it "queues the job" do
    ActiveJob::Base.queue_adapter = :test
    expect { ExpireListingJob.perform_later }.to have_enqueued_job
  end
end