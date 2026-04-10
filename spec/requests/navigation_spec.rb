# filepath: spec/requests/navigation_spec.rb
require "rails_helper"

RSpec.describe "Global Navigation Bar", type: :request do
  let(:user) do
    User.create!(
      name: "Alice",
      email: "alice@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # Helper: simulate login by posting to sessions#create
  def log_in_as(user)
    post sessions_path, params: { email: user.email, password: "password123" }
  end

  # ─── 未登录用户 ────────────────────────────────────────────────────────────

  describe "未登录用户访问首页" do
    before { get root_path }

    it "HTTP 200" do
      expect(response).to have_http_status(:ok)
    end

    it "导航栏包含站点 Logo" do
      expect(response.body).to include("CUHK Marketplace")
    end

    it "导航栏包含 Products 链接" do
      expect(response.body).to include(products_path)
    end

    it "导航栏包含 Chats 链接" do
      expect(response.body).to include(conversations_path)
    end

    it "导航栏包含 Payments 链接" do
      expect(response.body).to include(payments_path)
    end

    it "导航栏包含 Listings 链接" do
      expect(response.body).to include(listings_path)
    end

    it "右侧显示 Login 按钮" do
      expect(response.body).to include("Login")
    end

    it "不显示用户头像区域" do
      expect(response.body).not_to include("nav-avatar")
    end
  end

  # ─── 已登录用户 ────────────────────────────────────────────────────────────

  describe "已登录用户访问首页" do
    before do
      log_in_as(user)
      get root_path
    end

    it "HTTP 200" do
      expect(response).to have_http_status(:ok)
    end

    it "导航栏显示用户名字" do
      expect(response.body).to include(user.name)
    end

    it "显示用户头像区域" do
      expect(response.body).to include("nav-avatar")
    end

    it "下拉菜单包含 My Profile 链接" do
      expect(response.body).to include(user_path(user))
    end

    it "下拉菜单包含 Logout 链接" do
      expect(response.body).to include(session_path(user))
    end

    it "不显示 Login 按钮" do
      expect(response.body).not_to include(">Login<")
    end
  end

  # ─── 导航栏在所有主要页面均渲染 ───────────────────────────────────────────

  describe "导航栏跨页面一致性" do
    %i[products_path conversations_path payments_path listings_path].each do |path_helper|
      it "#{path_helper} 页面包含导航栏 Logo" do
        get send(path_helper)
        follow_redirect! if response.redirect?
        expect(response.body).to include("CUHK Marketplace")
      end
    end
  end
end
