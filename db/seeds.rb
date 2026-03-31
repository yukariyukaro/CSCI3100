User.find_or_create_by!(email: "demo_user@example.com") do |user|
  user.name = "Demo User"
  user.password = "password123"
  user.password_confirmation = "password123"
end

Product.create!([
  { name: "二手iPhone 13", description: "9成新，电池健康度85%，无拆修", price: 2500.00, condition: "9成新" },
  { name: "MacBook Pro 2021", description: "M1芯片，16GB内存，512GB硬盘，轻微使用痕迹", price: 7500.00, condition: "8成新" },
  { name: "计算机网络（第7版）", description: "大学教材，笔记较少", price: 20.00, condition: "7成新" },
  { name: "全新 AirPods Pro 2", description: "未拆封，年会奖品转让", price: 1500.00, condition: "全新" },
  { name: "二手自行车", description: "捷安特通勤车，骑了半年，车况良好", price: 300.00, condition: "8成新" }
])
