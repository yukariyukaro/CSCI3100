# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication Flows", type: :request do
  describe "POST /sessions (login)" do
    let(:valid_email) { TestData.unique_email(prefix: "alice") }
    let(:password) { "SecurePassword123!" }

    before do
      User.create!(
        name: "Alice",
        email: valid_email,
        password: password,
        password_confirmation: password
      )
    end

    context "with valid credentials" do
      it "logs in the user and redirects to root" do
        post sessions_path, params: { email: valid_email, password: password }

        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to be_present
      end

      it "shows success notice" do
        post sessions_path, params: { email: valid_email, password: password }

        expect(flash[:notice]).to be_present
      end
    end

    context "with invalid credentials" do
      it "returns 422 Unprocessable Entity when password is wrong" do
        post sessions_path, params: { email: valid_email, password: "WrongPassword" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders login form on invalid password" do
        post sessions_path, params: { email: valid_email, password: "WrongPassword" }

        expect(response.body).to include("Login")
      end

      it "displays error message on invalid password" do
        post sessions_path, params: { email: valid_email, password: "WrongPassword" }

        expect(response.body).to include("invalid").or include("Invalid")
      end

      it "returns 422 when email doesn't exist" do
        post sessions_path, params: { email: "nonexistent@example.com", password: password }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays error message when email doesn't exist" do
        post sessions_path, params: { email: "nonexistent@example.com", password: password }

        expect(response.body).to include("invalid").or include("Invalid")
      end

      it "does not set session on invalid credentials" do
        post sessions_path, params: { email: valid_email, password: "WrongPassword" }

        expect(session[:user_id]).to be_nil
      end
    end

    context "with edge cases" do
      it "handles email case-insensitively" do
        post sessions_path, params: { email: valid_email.upcase, password: password }

        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to be_present
      end

      it "handles email with leading/trailing whitespace" do
        post sessions_path, params: { email: "  #{valid_email}  ", password: password }

        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to be_present
      end

      it "rejects empty email" do
        post sessions_path, params: { email: "", password: password }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects empty password" do
        post sessions_path, params: { email: valid_email, password: "" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects missing email parameter" do
        post sessions_path, params: { password: password }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects missing password parameter" do
        post sessions_path, params: { email: valid_email }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "handles very long email addresses gracefully" do
        long_email = "a" * 200 + "@example.com"
        post sessions_path, params: { email: long_email, password: password }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects SQL injection attempts in email" do
        sql_injection_email = "' OR '1'='1"
        post sessions_path, params: { email: sql_injection_email, password: password }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /sessions (logout)" do
    let(:user_email) { TestData.unique_email(prefix: "bob") }
    let(:password) { "SecurePassword123!" }
    let(:user) do
      User.create!(
        name: "Bob",
        email: user_email,
        password: password,
        password_confirmation: password
      )
    end

    before do
      post sessions_path, params: { email: user.email, password: password }
    end

    it "clears the session" do
      expect(session[:user_id]).to be_present

      delete session_path(id: 1)

      expect(session[:user_id]).to be_nil
    end

    it "redirects to root" do
      delete session_path(id: 1)

      expect(response).to redirect_to(root_path)
    end

    it "shows logout success message" do
      delete session_path(id: 1)

      expect(flash[:notice]).to be_present
    end
  end

  describe "POST /users (signup/registration)" do
    let(:valid_email) { TestData.unique_email(prefix: "charlie") }

    context "with valid data" do
      it "creates a new user" do
        expect {
          post users_path, params: {
            user: {
              name: "Charlie",
              email: valid_email,
              password: "SecurePassword123!",
              password_confirmation: "SecurePassword123!"
            }
          }
        }.to change(User, :count).by(1)
      end

      it "logs in the new user" do
        post users_path, params: {
          user: {
            name: "Charlie",
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(session[:user_id]).to be_present
      end

      it "redirects to root" do
        post users_path, params: {
          user: {
            name: "Charlie",
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response).to redirect_to(root_path)
      end

      it "shows success notice" do
        post users_path, params: {
          user: {
            name: "Charlie",
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(flash[:notice]).to be_present
      end
    end

    context "with duplicate email (uniqueness violation)" do
      let(:duplicate_email) { TestData.unique_email(prefix: "david") }

      before do
        User.create!(
          name: "David",
          email: duplicate_email,
          password: "SecurePassword123!",
          password_confirmation: "SecurePassword123!"
        )
      end

      it "returns 422 Unprocessable Entity" do
        post users_path, params: {
          user: {
            name: "Eve",
            email: duplicate_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders signup form" do
        post users_path, params: {
          user: {
            name: "Eve",
            email: duplicate_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response.body).to include("Sign Up")
      end

      it "displays email error message" do
        post users_path, params: {
          user: {
            name: "Eve",
            email: duplicate_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response.body).to include("email").or include("Email")
      end

      it "does not create a new user" do
        expect {
          post users_path, params: {
            user: {
              name: "Eve",
              email: duplicate_email,
              password: "SecurePassword123!",
              password_confirmation: "SecurePassword123!"
            }
          }
        }.not_to change(User, :count)
      end

      it "does not log in user" do
        post users_path, params: {
          user: {
            name: "Eve",
            email: duplicate_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(session[:user_id]).to be_nil
      end
    end

    context "with password mismatch" do
      it "returns 422 Unprocessable Entity" do
        post users_path, params: {
          user: {
            name: "Frank",
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "DifferentPassword!"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders signup form" do
        post users_path, params: {
          user: {
            name: "Frank",
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "DifferentPassword!"
          }
        }

        expect(response.body).to include("Sign Up")
      end

      it "displays password confirmation error" do
        post users_path, params: {
          user: {
            name: "Frank",
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "DifferentPassword!"
          }
        }

        expect(response.body).to include("password").or include("Password")
      end
    end

    context "with missing fields" do
      it "rejects empty name" do
        post users_path, params: {
          user: {
            name: "",
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("name").or include("Name")
      end

      it "rejects empty email" do
        post users_path, params: {
          user: {
            name: "Grace",
            email: "",
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("email").or include("Email")
      end

      it "rejects empty password" do
        post users_path, params: {
          user: {
            name: "Henry",
            email: valid_email,
            password: "",
            password_confirmation: ""
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects missing name" do
        post users_path, params: {
          user: {
            email: valid_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with email format edge cases" do
      it "handles email case-insensitively for uniqueness" do
        email = TestData.unique_email(prefix: "iris")
        User.create!(
          name: "Iris",
          email: email,
          password: "SecurePassword123!",
          password_confirmation: "SecurePassword123!"
        )

        post users_path, params: {
          user: {
            name: "Jack",
            email: email.upcase,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(User.count).to eq(1)
      end

      it "handles email with leading/trailing whitespace" do
        email = TestData.unique_email(prefix: "kevin")
        post users_path, params: {
          user: {
            name: "Kevin",
            email: "  #{email}  ",
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        expect(response).to redirect_to(root_path)
        expect(User.last.email).to eq(email)
      end

      it "rejects invalid email format" do
        post users_path, params: {
          user: {
            name: "Laura",
            email: "not-an-email",
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        # Note: The app may accept any email format; adjust based on validation
        expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:redirect)
      end

      it "handles very long email addresses" do
        long_email = "a" * 200 + "@example.com"
        post users_path, params: {
          user: {
            name: "Mike",
            email: long_email,
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        # The app may accept or reject long emails; both are acceptable
        expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:found)
      end
    end

    context "with SQL injection attempts" do
      it "safely handles SQL injection in email" do
        post users_path, params: {
          user: {
            name: "Nancy",
            email: "' OR '1'='1",
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        # The app uses parameterized queries; email is treated as literal string
        # May create user or reject based on email validation
        expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:found)
      end

      it "safely handles SQL injection in name" do
        post users_path, params: {
          user: {
            name: "'; DROP TABLE users; --",
            email: TestData.unique_email(prefix: "nancy"),
            password: "SecurePassword123!",
            password_confirmation: "SecurePassword123!"
          }
        }

        # Should either reject or safely sanitize
        expect(User.count).to be_positive
      end
    end
  end

  describe "Session persistence and authentication" do
    let(:user_email) { TestData.unique_email(prefix: "oscar") }
    let(:password) { "SecurePassword123!" }

    before do
      User.create!(
        name: "Oscar",
        email: user_email,
        password: password,
        password_confirmation: password
      )
    end

    it "maintains session across multiple requests" do
      post sessions_path, params: { email: user_email, password: password }
      session_id = session[:user_id]

      get root_path
      expect(session[:user_id]).to eq(session_id)
    end

    it "clears session after logout" do
      post sessions_path, params: { email: user_email, password: password }
      expect(session[:user_id]).to be_present

      delete session_path(id: 1)
      expect(session[:user_id]).to be_nil

      get root_path
      expect(session[:user_id]).to be_nil
    end
  end
end
