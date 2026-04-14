communities = [
  { name: "Chung Chi", abbreviation: "CC", slug: "chung-chi", description: "Chung Chi College" },
  { name: "New Asia", abbreviation: "NA", slug: "new-asia", description: "New Asia College" },
  { name: "United", abbreviation: "UC", slug: "united", description: "United College" },
  { name: "Shaw", abbreviation: "SC", slug: "shaw", description: "Shaw College" },
  { name: "Morningside", abbreviation: "MC", slug: "morningside", description: "Morningside College" },
  { name: "S.H. Ho", abbreviation: "SHHO", slug: "sh-ho", description: "S.H. Ho College" },
  { name: "C.W. Chu", abbreviation: "CWC", slug: "cw-chu", description: "C.W. Chu College" },
  { name: "Wu Yee Sun", abbreviation: "WYS", slug: "wu-yee-sun", description: "Wu Yee Sun College" },
  { name: "Lee Woo Sing", abbreviation: "LWS", slug: "lee-woo-sing", description: "Lee Woo Sing College" }
]

communities.each do |attrs|
  Community.find_or_create_by!(slug: attrs[:slug]) do |c|
    c.name = attrs[:name]
    c.abbreviation = attrs[:abbreviation]
    c.description = attrs[:description]
  end
end

Community.find_or_create_by!(slug: "cuhk") do |c|
  c.name = "CUHK Main Campus"
  c.abbreviation = "CUHK"
  c.description = "Default community for backfill"
end

demo_community = Community.find_by!(slug: "chung-chi")
demo_user = User.find_or_create_by!(email: "demo_user@example.com") do |user|
  user.name = "Demo User"
  user.community = demo_community
  user.password = "password123"
  user.password_confirmation = "password123"
end

[
  { name: "二手iPhone 13", description: "9成新，电池健康度85%，无拆修，带原装盒子", price: 2500.00, condition: "Like New" },
  { name: "MacBook Pro 2021", description: "M1芯片，16GB内存，512GB硬盘，轻微使用痕迹", price: 7500.00, condition: "Good" },
  { name: "计算机网络（第7版）", description: "大学教材，笔记较少，内容完整无缺页", price: 20.00, condition: "Fair" },
  { name: "全新 AirPods Pro 2", description: "未拆封，年会奖品转让，支持降噪功能", price: 1500.00, condition: "Like New" },
  { name: "二手自行车", description: "捷安特通勤车，骑了半年，车况良好，定期保养", price: 300.00, condition: "Good" }
].each do |attrs|
  Product.find_or_create_by!(name: attrs[:name]) do |p|
    p.description = attrs[:description]
    p.price       = attrs[:price]
    p.condition   = attrs[:condition]
    p.seller_id   = demo_user.id
  end
end

Product.where(seller_id: nil).find_each do |p|
  p.update!(seller_id: demo_user.id)
end
