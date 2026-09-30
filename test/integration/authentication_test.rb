require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  test 'redirects unauthenticated users to login' do
    get projects_path
    assert_redirected_to login_path
  end

  test 'can sign in' do
    sign_in(users(:demo))
    assert_response :success
  end

  test 'can sign up' do
    post signup_path, params: {
      user: { email: 'new@example.com', name: 'New', password: 'password123', password_confirmation: 'password123' }
    }
    assert_redirected_to projects_path
  end

  test 'rejects invalid credentials' do
    post login_path, params: { email: users(:demo).email, password: 'wrong' }
    assert_response :unprocessable_entity
  end

  test 'can sign out' do
    sign_in(users(:demo))
    delete logout_path
    assert_redirected_to login_path
  end
end
