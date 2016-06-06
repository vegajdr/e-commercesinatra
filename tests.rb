require 'pry'
require 'minitest/autorun'
require 'minitest/focus'

require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

require 'rack/test'
require './app'

class AppTests < Minitest::Test
  include Rack::Test::Methods

  def app
    ShopDBApp
  end

  def setup
    ShopDBApp.reset_database
  end

  def make_existing_user
    User.create! first_name: "Existing", last_name: "User", password: "hunter2"
  end

  def make_item
    Item.create! description: "Old Busted", price: 3.50
  end

  def test_can_add_users
    assert_equal 0, User.count

    r = post "/users", first_name: "New", last_name: "User", password: "password"

    assert_equal 200, r.status
    assert_equal 1, User.count
    assert_equal "New", User.first.first_name
  end

  def test_users_can_add_items
    user = make_existing_user
    header "Authorization", user.password
    assert_equal 0, Item.count

    r = post "/items", description: "New Hotness", price: 100.00

    assert_equal 200, r.status
    assert_equal 1, Item.count
    assert_equal "New Hotness", Item.first.description
  end

  def test_users_can_buy_items
    item = make_item
    user = make_existing_user
    header "Authorization", user.password

    r = post "/items/#{item.id}/buy", quantity: 5

    assert_equal 200, r.status
    assert_equal 1, Purchase.count
    assert_equal 5, Purchase.first.quantity
    assert_equal Purchase.first, user.purchases.first
  end

  def test_users_cant_buy_non_items
    user = make_existing_user
    header "Authorization", user.password

    assert_raises ActiveRecord::RecordNotFound do
      post "/items/99999/buy", quantity: 5
    end

    assert_equal 0, Purchase.count
  end

  def test_users_cant_delete_arbitrary_items
    item = make_item
    user = make_existing_user
    header "Authorization", user.password

    r = delete "/items/#{item.id}"

    assert_equal 403, r.status
    assert_equal 1, Item.count
  end

  def test_users_can_delete_their_items
    item = make_item
    user = make_existing_user
    header "Authorization", user.password

    item.listed_by = user
    item.save!
    r = delete "/items/#{item.id}"

    assert_equal 200, r.status
    assert_equal 0, Item.count
  end

  def test_users_can_see_who_has_ordered_an_item
    item = make_item
    3.times do |i|
      u = User.create! first_name: i, last_name: i, password: "pass#{i}"
      u.purchases.create! item: item, quantity: 4
    end

    r = get "/items/#{item.id}/purchases"

    assert_equal 200, r.status
    body = JSON.parse r.body
    assert_equal 3, body.count
  end
end
