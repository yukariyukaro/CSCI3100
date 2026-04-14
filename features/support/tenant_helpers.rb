module TenantHelpers
  def default_community
    Community.find_or_create_by!(slug: "test-default") do |c|
      c.name = "Test Default"
      c.abbreviation = "TST"
      c.description = "Test default community"
    end
  end

  delegate :slug, to: :default_community, prefix: true
end

World(TenantHelpers)

Before do
  default_community
end
