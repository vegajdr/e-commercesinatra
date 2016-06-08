require "sinatra/base"
require "./db/setup"
require "./lib/all"


# This is a starting point. Feel free to add / modify, as long as the tests pass
class ShopDBApp < Sinatra::Base
  set :logging, true
  set :show_exceptions, false

  def user
    User.find_by(password: env["HTTP_AUTHORIZATION"])
  end


  error do |e|
    #binding.pry
    raise e
  end

  post "/users" do
    User.where(
    first_name: params[:first_name],
    last_name: params[:last_name],
    password: params[:password]).first_or_create!
  end

  post "/items" do
    item = user.add_item params[:description], params[:price]
  end

  post "/items/:id/buy" do
    item = Item.where(id: params[:id]).first
    if item != nil
      purchase = user.create_order item, params[:quantity]
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  get "/items/:id/purchases" do
    items = Item.where(id: params[:id])
    items.first.users.to_json
  end

  delete "/items/:id" do
    item = Item.find_by(id: params[:id])
    if item.listed_by == user
      item.delete
      status 200
    else
      status 403
    end
  end

  def self.reset_database
    [User, Item, Purchase].each { |klass| klass.delete_all }
  end

  def parsed_body
    @parsed_body ||= JSON.parse request.body.read

  end




end
