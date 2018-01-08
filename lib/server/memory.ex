defmodule Twitter.Server.Memory do

    def create_users_table do
        :ets.new(:user_lookup, [:set, :public, :named_table])
        :ets.new(:hashtag_table, [:set, :public, :named_table])
        :ets.new(:username_table, [:set, :public, :named_table])
    end

    def register_new_user(username, password) do        
        if check_username(username) == false do
            :ets.insert_new(:user_lookup, {username, password, :null, false, :null, [], [], []})
            {:ok, "User #{username} registered successfully."}
        else
            {:error, "Username #{username} already exist."}
        end
        
    end

    def get_node_name(username) do
        case :ets.lookup(:user_lookup, username) do
            [{_, _, node_name, _, _, _, _, _}] -> {:ok, node_name}
            [] -> {:error, "Unable to retrieve node name because username is invalid"}
        end        
    end

    def get_online_status(username) do
        case :ets.lookup(:user_lookup, username) do
            [{_, _, socket, _, _, _, _, _}] -> 
                if socket != :null do
                {:ok, true}
                else
                    {:error, "Invalid Socket Id"}
                end
            [] -> {:error, "Unable to retrieve login status because username is invalid"}
        end        
    end    

    def check_username(username) do
        case :ets.lookup(:user_lookup, username) do
            [{_, _, _, _, _, _, _, _}] -> true
            [] -> false
        end
    end

    def authenticate_user(username, password, session_Id) do
        case :ets.lookup(:user_lookup, username) do
            [{username, pass, node_name, login, id, tweet_list, following_list, follower_list}] -> 
                if login == false do
                    if pass = password do
                        :ets.insert(:user_lookup, {username, password, session_Id, true, session_Id, tweet_list, following_list, follower_list})
                        {:ok, "Welcome Back #{username}!!"}    
                    else
                        {:error, "Wrong Password"}                       
                    end
 
                else
                    {:error, "You are already logged in"}
                end                
            [] -> {:error, "Username is invalid"}
        end
    end

    def logout_user(username, session_Id) do
        case :ets.lookup(:user_lookup, username) do
            [{username, password, node_name, _, id, tweet_list, following_list, follower_list}] ->                
                if session_Id == id do
                    :ets.insert(:user_lookup, {username, password, node_name, false, :null, tweet_list, following_list, follower_list})  
                    {:ok, "#{username} successfully logged out"}    
                else
                    {:error, "Unable to logout because the session is invalid"} 
                end          
            [] -> {:error, "Unable to logout #{username}"} 
        end
    end

    def get_tweets(username) do
        case :ets.lookup(:user_lookup, username) do
            [{_, _, _, _, _, tweet_list, _, _}] -> {:ok, tweet_list}
            [] -> {:error, "Unable to retrieve tweets because username is invalid"}
        end
    end

    def insert_tweet(username, tweet) do
        case :ets.lookup(:user_lookup, username) do
            [{username, password, node_name, login_state, session_Id, tweet_list, following_list, follower_list}] -> 
                :ets.insert(:user_lookup, {username, password, node_name, login_state, session_Id, [tweet | tweet_list], following_list, follower_list})
                {:ok, "Tweet successfully sent"}
            [] -> {:error, "Unable to send tweet. Please try again."}
        end       
    end    

    def insert_follower(followed_username, follower_username) do        
        case :ets.lookup(:user_lookup, followed_username) do
            [{username, password, node_name, login_state, session_Id, tweet_list, following_list, follower_list}] -> 
                :ets.insert(:user_lookup, {username, password, node_name, login_state, session_Id, tweet_list, following_list, [follower_username | follower_list]})
                {:ok, ""}
            [] -> {:error, ""}
        end     
    end    
    
    def insert_following(followed_username, follower_username) do        
        case :ets.lookup(:user_lookup, follower_username) do
            [{username, password, node_name, login_state, session_Id, tweet_list, following_list, follower_list}] -> 
                :ets.insert(:user_lookup, {username, password, node_name, login_state, session_Id, tweet_list, [followed_username | following_list], follower_list})
                {:ok, "You have started following #{followed_username}"}
            [] -> {:error, "Unable to follow #{followed_username}"}
        end     
    end

    def get_follower(username) do        
        case :ets.lookup(:user_lookup, username) do
            [{_, _, _, _, _, _, _, follower_list}] ->                
                {:ok, follower_list}
            [] -> {:error, []}
        end     
    end     

    def get_following(username) do        
        case :ets.lookup(:user_lookup, username) do
            [{_, _, _, _, _, _, following_list, _}] ->                
                {:ok, following_list}
            [] -> {:error, []}
        end     
    end
    
    def remove_follower(followed_username, follower_username) do        
        case :ets.lookup(:user_lookup, followed_username) do
            [{username, password, node_name, login_state, tweet_list, following_list, follower_list}] -> 
                follower_list = List.delete(follower_list, follower_username)
                :ets.insert(:user_lookup, {username, password, node_name, login_state, tweet_list, following_list, follower_list})
                {:ok, ""}
            [] -> {:error, ""}
        end     
    end    
    
    def remove_following(followed_username, follower_username) do        
        case :ets.lookup(:user_lookup, follower_username) do
            [{username, password, node_name, login_state, tweet_list, following_list, follower_list}] -> 
                following_list = List.delete(following_list, followed_username)
                :ets.insert(:user_lookup, {username, password, node_name, login_state, tweet_list, following_list, follower_list})
                {:ok, "You have successfully unfollowed #{followed_username}"}
            [] -> {:error, "Unable to unfollow #{followed_username}"}
        end     
    end

    def insert_hashtag(hashtag, tweet) do
        [tag | _] = hashtag
        
        case :ets.lookup(:hashtag_table, tag) do
            [{tag, tweet_list}] ->                
                :ets.insert(:hashtag_table, {tag, [tweet | tweet_list]})
            [] -> :ets.insert_new(:hashtag_table, {tag, [tweet]})
        end
    end

    def insert_username(username, tweet) do
        [user | _] = username
        
        case :ets.lookup(:username_table, user) do
            [{user, tweet_list}] ->
                :ets.insert(:username_table, {user, [tweet | tweet_list]})
            [] -> :ets.insert(:username_table, {user, [tweet]})
        end
    end

    def get_hashtag(hashtag) do        
        case :ets.lookup(:hashtag_table, hashtag) do
            [{hashtag, tweet_list}] -> tweet_list
            [] -> "Cannot find the hashtag #{hashtag}"
        end
    end
    
    def get_username(username) do        
        case :ets.lookup(:username_table, username) do
            [{username, tweet_list}] -> tweet_list
            [] -> "Cannot find the Username #{username}"
        end
    end    
end