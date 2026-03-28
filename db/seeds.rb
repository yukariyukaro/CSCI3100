User.find_or_create_by!(email: "demo_user@example.com") do |user|
  user.name = "Demo User"
  user.password = "password123"
  user.password_confirmation = "password123"
end
