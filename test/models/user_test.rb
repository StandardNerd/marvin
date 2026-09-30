require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'requires email' do
    user = User.new(name: 'Test', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test 'requires unique email' do
    user = User.new(email: users(:demo).email, name: 'Test', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'requires valid email format' do
    user = User.new(email: 'invalid', name: 'Test', password: 'password123')
    assert_not user.valid?
  end

  test 'requires name' do
    user = User.new(email: 'test@example.com', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test 'normalizes email' do
    user = User.new(email: '  TEST@EXAMPLE.COM  ', name: 'Test', password: 'password123')
    user.valid?
    assert_equal 'test@example.com', user.email
  end

  test 'has many projects' do
    assert_respond_to users(:demo), :projects
  end
end
