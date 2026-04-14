module TenantTestHelpers
  def default_community
    Community.find_or_create_by!(slug: "test-default") do |c|
      c.name = "Test Default"
      c.abbreviation = "TST"
      c.description = "Test default community"
    end
  end

  def create_community(name: nil, abbreviation: nil, slug: nil, description: nil)
    suffix = SecureRandom.hex(4)
    Community.create!(
      name: name || "Community #{suffix}",
      abbreviation: abbreviation || "C#{suffix[0, 3].upcase}",
      slug: slug || "community-#{suffix}",
      description: description
    )
  end
end
