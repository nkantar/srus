# srus.rb
require 'rubygems'
require 'sinatra'
require 'data_mapper'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/links.db")

class Link
  include DataMapper::Resource
  property :id, Serial
  property :link, String, :length => 512, :required => true
  property :short, String, :length => 4, :required => true
end

DataMapper.finalize.auto_upgrade!

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not Authorized\n"])
    end
  end
  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'pass']
  end
end

get '/' do
  protected!
  redirect '/list'
end

get '/list/?' do
  protected!
  @links = Link.all(:order => [ :id.asc ])
  erb :list
end

get '/new/?' do
  protected!
  erb :new
end

post '/new/?' do
  protected!
  l = Link.new
  l.link = params[:link]
  l.short = params[:short]
  l.save
  redirect '/'
end

get '/:linkhash' do
  @link = Link.first(:short => params[:linkhash])
  redirect @link.link, 303
end
