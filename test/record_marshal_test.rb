# frozen_string_literal: true

require "test_helper"

class RecordMarshalTest < ActiveSupport::TestCase
  def setup
    @json_options = { "name" => "Test", "age" => 18, "hash" => { "name" => "dup" } }
    @extras = { "tagline" => "Hello world", "gender" => 1 }
    @user = User.create name: "csdn",
                        email: "test@csdn.com",
                        options: [1, 2],
                        extras: @extras,
                        json_options: @json_options,
                        status: :active
  end

  def test_should_dump_active_record_object
    dumped = RecordMarshal.dump(@user)
    assert dumped.is_a?(Array)
    assert_equal "User", dumped[0]
    assert_equal(
      dumped[1].slice(:id, :options, :json_options, :extras, :status, :name, :email),
      ActiveRecord::Base.connection.select_all(User.where(id: @user.id)).first.slice(:id, :options, :json_options, :extras, :status, :name, :email)
    )
  end

  def test_should_load_active_record_object
    @user.write_second_level_cache
    assert_equal @user, User.read_second_level_cache(@user.id)
    assert_equal Array, User.read_second_level_cache(@user.id).options.class
    assert_equal User.read_second_level_cache(@user.id).changed?, false
    assert_equal [1, 2], User.read_second_level_cache(@user.id).options
    assert_equal @extras, User.read_second_level_cache(@user.id).extras
    assert_equal "Hello world", User.read_second_level_cache(@user.id).tagline
    assert_equal 1, User.read_second_level_cache(@user.id).gender
    result = User.read_second_level_cache(@user.id)
    assert_equal @json_options["name"], result.json_options["name"]
    assert_equal @json_options, result.json_options
    assert User.read_second_level_cache(@user.id).persisted?
    assert_equal Array, User.read_second_level_cache(@user.id).reload.options.class
  end

  def test_should_load_nil
    @user.expire_second_level_cache
    assert_nil User.read_second_level_cache(@user.id)
  end

  def test_should_load_active_record_object_without_association_cache
    @user.books
    @user.write_second_level_cache
    assert_equal false, User.read_second_level_cache(@user.id).association_cached?("id")
  end

  def test_should_thread_safe_load
    user = User.find @user.id
    assert_equal "active", user.status
    user = User.find @user.id
    assert_equal "active", user.status
  end
end
