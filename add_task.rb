require 'sinatra'
require 'data_mapper'

set :sessions,true

DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/tweet.db")
 
class User
 	include DataMapper::Resource
 	property :id,Serial
 	property :email,String
 	property :password,String
 	property :name,String
 end

class Task
    include DataMapper::Resource
    property :id, Serial
    property :content, String
    property :done, Boolean
    property :user_id,Integer
    # property :like,Boolean
    # property :dislike,Boolean
end
 
class Searate
	include DataMapper::Resource
 	property :id,Serial
 	property :follower_id,Integer
 	property :followee_id,Integer
 	property :yyy,Boolean, :default=>true
end

class Follow
include DataMapper::Resource
 	property :id,Serial
 	property :user,Integer
 	property :count,Integer

end

class Likes
	include DataMapper::Resource
 	property :id,Serial
 	property :user,Integer
 	property :task_id,Integer
end

class Countlike
	include DataMapper::Resource
    property :id,Serial
 	property :task_id,Integer
 	property :count,Integer
end

DataMapper.finalize
DataMapper.auto_upgrade!


# This Is Default Page ---------
get '/' do 

	user=nil
	if session[:user_id]
	user=User.get(session[:user_id])
	else
	redirect '/login'	
	end
	task=Task.all
	user1=User.all
	follow=Follow.all(:user=>session[:user_id]).first
	if follow
    #puts "follow count in '/' is  : #{follow.count}"
    searate=Searate.all(:followee_id=>session[:user_id])
    # countlikes=Countlike.all()
	end
	erb :index ,locals: {:user=>user,:task=>task,:user1=>user1,:follow=>follow ,:searate=>searate}
end

# This Is Login page by Get-----
get '/login' do
	erb :login
end
 
# THis Is Login Page By Post
post '/login' do
email=params[:email]
password=params[:password]
#puts "password :#{password}"
user=User.all(:email=>email).first

if user
	#puts "user password : #{user.password}"
	if user.password==password
		#puts "you successfully logged in"
		session[:user_id]=user.id
		redirect '/'
	else
	#puts "password is wrong"
	redirect '/login'	
	end
else
#puts "you are not a registerd user "
redirect '/register'
end
end


# This Is Register page by get
get '/register' do
	erb :register
end


# This Is Register page by post
post '/register' do

#puts "in register post block"

email=params[:email]
password=params[:password]
name=params[:name]
user=User.new
user.email=email;
user.password=password;
user.name=name
user.save
session[:user_id]=user.id
puts "hello" 
follow=Follow.new
follow.user=user.id
follow.count=0
follow.save
#puts "after register follow_user is : #{follow.user} "
#puts " follow_count is : #{follow.count}"
redirect '/'
end


# This Is Add Task Page By Post
post '/add_task' do
#puts "in post add_task"
add_task=params[:add_task]
#puts "add_task is :#{add_task}"
task=Task.new
task.content=add_task
task.done=false
task.user_id=session[:user_id]
# task.like=true
# task.dislike=false
task.save
#puts "task content is :#{task.content}"

 searate=Searate.new
 searate.followee_id=session[:user_id]
 searate.follower_id =session[:user_id]
 searate.save
 follow =Follow.all(:user=>session[:user_id]).first
 if follow
 follow.count+=1
  follow.save
else
follow=Follow.new
follow.user=session[:user_id]
follow.count=1;
follow.save

 end

redirect '/'

end



# This Is Logout Page By Post
post '/logout' do
	session[:user_id]=nil
	redirect '/login'
end


# This is follow page by post
post '/follow' do
 follower_id=params[:follower_id]
 #puts "follower_id is : #{follower_id}"
 followee_id=params[:followee_id]
 #puts "followee_id is : #{followee_id}"
 table=Searate.all(:followee_id=>followee_id, :follower_id=>follower_id).first
  #puts "table is : #{table}"
 if table
 redirect '/'
 else
 #puts "in follow else "
 searate=Searate.new
 searate.followee_id=followee_id
 searate.follower_id =follower_id
 searate.save
 follow =Follow.all(:user=>followee_id).first
 if follow
 follow.count+=1
  follow.save
else
follow=Follow.new
follow.user=follower_id
follow.count=1;
follow.save

 end
 #puts "follow count is :#{follow.count}"

 redirect '/'
 end

end


# This is unfollow page by post
post '/unfollow' do
follower_id=params[:follower_id]
followee_id=params[:followee_id]
searate=Searate.all(:followee_id=>followee_id,:follower_id=>follower_id).first
#puts "in unfollow searate is : #{searate}"
if searate
#puts "in unfollow searate if statement :"
follow =Follow.all(:user=>followee_id).first
follow.count-=1
follow.save
searate.destroy
redirect '/'
else
#puts "in unfollow searate else statement :"
redirect '/'
end

end


# This is like page by post
post '/like' do

 task_id=params[:task_id]
 user_id=params[:user_id]
 table=Likes.all(:task_id=>task_id, :user=>user_id).first
 #puts "table is : #{table}"
 if table
 redirect '/'
 else
 #puts "in like else "
 likes=Likes.new
 likes.task_id=task_id
 likes.user=user_id
 likes.save

 countlikes=Countlike.all(:task_id=>task_id).first
 if countlikes
 	countlikes.count+=1
 	 countlikes.save

 else
 	ct=Countlike.new
 	ct.task_id=task_id
 	ct.count=1
 	ct.save
#puts "likes  are : #{ct.count}"
 end
 
 redirect '/'
 end

end


# This is unlike page by post
post '/unlike' do
task_id=params[:task_id]
user_id=params[:user_id]
table=Likes.all(:task_id=>task_id, :user=>user_id).first
if table
	table.destroy
	countlikes=Countlike.all(:task_id=>task_id).first
    countlikes.count-=1
    countlikes.save 
	redirect '/'
else
	redirect '/'
end
end


# This is update page by post
post '/update' do

task_id=params[:task_id]
user_id=params[:user_id].to_i

#puts "user_id is : #{user_id} ,classs is :#{user_id.class}"
#puts "user session id is : #{session[:user_id]} classs is : #{session[:user_id].class}"
session_id=session[:user_id]
if user_id==session_id
#puts "inside update if statement"
erb :update ,locals:{:task_id=>task_id}
else
redirect '/'
end
end


# This is update content page by post
post '/updatecontent' do

task_id=params[:task_id]
puts "in post updatecontent"
content=params[:content]
puts "task id from params is #{task_id}"
puts "content is :#{content}"

task=Task.all(:id=>task_id).first
puts "task is :#{task}"
puts "task id is :#{task.id}"
puts "task content is :#{task.content}"

task.content=content
task.done=false
task.user_id=session[:user_id]
# task.like=true
# task.dislike=false
task.save
puts "task content is :#{task.content}"
redirect '/'
end

# This Is FInd Page By post
post '/find' do
email=params[:email]
user=User.all(:email=>email).first
if user
	user=User.all(:email=>email)
	erb :find, locals:{:user=>user}
else
	redirect '/'
end
end