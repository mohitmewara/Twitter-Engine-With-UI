defmodule Twitter.Server.Engine do
    use GenServer
    use Phoenix.Channel
    alias Twitter.Server.Memory

    def start_link do
        Memory.create_users_table
        GenServer.start_link(__MODULE__, [0], name: :twitter_engine)
    end

    def handle_call({:user_register, username, password}, _from, state) do        
       {:reply, Memory.register_new_user(username, password), state}   
    end

    def handle_call({:user_login, username, password, socket}, _from, state) do
        #session_Id = :crypto.hash(:sha256, username.to) |> Base.encode16
        {:reply, Memory.authenticate_user(username, password, socket), state}
    end

    def handle_call({:user_logout, username, session_Id}, _from, state) do
        {:reply, Memory.logout_user(username, session_Id), state}        
    end

    def handle_call({:hit_counter}, _from, state) do
        count = Enum.at(state, 0)
        {:reply, count, state}        
    end

    def handle_call({:fetch_tweets, username, session_key}, _from, state) do
        
        {:reply, state}
    end    

    def handle_call({:follow, followed_username, follower_username}, _from, state) do
        case Memory.insert_follower(followed_username, follower_username) do
            {:ok, msg} ->
                message = Memory.insert_following(followed_username, follower_username)            
            {:error, msg} -> {:reply, msg, state}            
        end
        {:reply, message, state}
    end

    def handle_call({:unfollow, followed_username, follower_username, follower_session_key}, _from, state) do        
        {:reply, state}
    end

    def handle_call({:follower, username, follower_session_key}, _from, state) do        
        {:reply, Memory.get_follower(username), state}
    end
    
    def handle_call({:following, username, follower_session_key}, _from, state) do
        {:reply, Memory.get_following(username), state}        
    end    
    
    def handle_cast({:send_tweet, username, tweet}, state) do
        case Memory.get_online_status(username) do
            {:ok, login} -> 
                if login == true do
                    hashtags = Regex.scan(~r/\B#[á-úÁ-Úä-üÄ-Üa-zA-Z0-9_]+/, tweet)
                    usernames=  Regex.scan(~r/\B@[á-úÁ-Úä-üÄ-Üa-zA-Z0-9_]+/, tweet)
                
                    hashtags |> (Enum.each fn(x) -> Memory.insert_hashtag(x, tweet) end )
                    usernames |> (Enum.each fn(x) -> Memory.insert_username(x, tweet) end )
            
                    counter = Enum.at(state, 0)

                    case Memory.insert_tweet(username, tweet) do
                        {:ok, msg} ->
                            case Memory.get_follower(username) do
                                {:ok, follower_list} ->
                                    len = length(follower_list)
                                    counter = counter + len
                                    for follower <- follower_list do
                                        case Memory.get_online_status(follower) do
                                            {:ok, status} -> 
                                                if status == true do
                                                    case Memory.get_node_name(follower) do                                                      
                                                       {:ok, node_name} ->         
                                                            IO.inspect follower                                       
                                                            push  node_name, "receive_tweet", %{"message" => tweet, "name" => username} 
                                                       {:error, msg} -> IO.inspect msg
                                                   end
                                                end
                                            {:error, _} -> "Error in getting login status"                                                                           
                                        end                         
                                    end
                                {:error, _} -> "Error in getting follower list"
                            end
                        {:error, msg} -> IO.inspect "Error in sending tweet"    
                    end             
                end                       
        end
        {:noreply, [counter]}
    end

    def handle_cast({:retweet, username1, username2, tweet}, state) do
        counter = Enum.at(state, 0)        
        case Memory.insert_tweet(username1, tweet) do
            {:ok, msg} ->
                case Memory.get_follower(username1) do
                    {:ok, follower_list} ->
                        len = length(follower_list)
                        counter = counter + len
                        for follower <- follower_list do
                            case Memory.get_online_status(follower) do
                                {:ok, status} -> 
                                    if status == true do
                                        case Memory.get_node_name(follower) do                                          
                                           {:ok, node_name} ->  
                                            counter = counter + 1
                                            push  node_name, "receive_retweet", %{"message" => tweet, "username1" => username1, "username2" => username2}
                                            #GenServer.cast({follower, node_name}, {:receive_retweet, username1, username2, tweet}) 
                                           {:error, msg} -> IO.inspect msg
                                       end
                                    end
                                {:error, _} -> "Error in getting login status"                                                                           
                            end                         
                        end
                    {:error, _} -> "Error in getting follower list"
                end
            {:error, msg} -> IO.inspect "Error in sending tweet"    
        end                 
        {:noreply, [counter]}
    end    
    
    def handle_call({:search_following_tweet, keyword}, _from, state) do        
        {:reply, state}
    end

    def handle_call({:search_hashtag, tag}, _from, state) do        
        counter = Enum.at(state, 0)
        counter = counter + 1        
        {:reply, Memory.get_hashtag(tag), [counter]}
    end
    
    def handle_call({:search_user, username}, _from, state) do   
        counter = Enum.at(state, 0)
        counter = counter + 1        
        {:reply, Memory.get_username(username), [counter]}
    end    

end