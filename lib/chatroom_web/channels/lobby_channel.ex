defmodule Chatroom.LobbyChannel do
    use Phoenix.Channel
    alias Chatroom.Memory
  
    def join("lobby", _payload, socket) do
      {:ok, socket}
    end
  
    def handle_in("register", payload, socket) do          
      username = Map.get(payload, "name")
      password = Map.get(payload, "password")
      IO.inspect GenServer.call(:twitter_engine, {:user_register, username, password})      
      {:noreply, socket}
    end

    def handle_in("login", payload, socket) do
      username = Map.get(payload, "name")
      password = Map.get(payload, "password")
      IO.inspect  GenServer.call(:twitter_engine, {:user_login, username, password, socket})
      {:noreply, socket}
    end
    
    def handle_in("logout", payload, socket) do
      username = Map.get(payload, "name")      
      IO.inspect  GenServer.call(:twitter_engine, {:user_logout, username, socket})
      {:noreply, socket}
    end

    def handle_in("follow", payload, socket) do
      followed_username = Map.get(payload, "following")
      follower_username = Map.get(payload, "follower")      
      IO.inspect  GenServer.call(:twitter_engine, {:follow, followed_username, follower_username})
      {:noreply, socket}
    end

    def handle_in("send_tweet", payload, socket) do
      username = Map.get(payload, "name")
      tweet = Map.get(payload, "tweet")      
      IO.inspect  GenServer.cast(:twitter_engine, {:send_tweet, username, tweet})
      {:noreply, socket}
    end       

    def handle_in("send_retweet", payload, socket) do
      username1 = Map.get(payload, "username1")
      username2 = Map.get(payload, "username2")
      tweet = Map.get(payload, "tweet")            
      IO.inspect  GenServer.cast(:twitter_engine, {:retweet, username1, username2, tweet})
      {:noreply, socket}
    end    

    def handle_in("search_hashtag", payload, socket) do      
      hashtag = Map.get(payload, "hashtag")      
      response =  GenServer.call(:twitter_engine, {:search_hashtag, hashtag})
      msg = "Search result for hashtag #{hashtag} : #{response}"
      push  socket, "receive_response", %{"message" => msg}
      {:noreply, socket}
    end  

    def handle_in("search_username", payload, socket) do
      username = Map.get(payload, "username")      
      response =  GenServer.call(:twitter_engine, {:search_user, username})
      msg = "Search result for username #{username} : #{response}"
      push  socket, "receive_response", %{"message" => msg}
      {:noreply, socket}
    end  

    def handle_in("receive_tweet", payload, socket) do      
      {:noreply, socket}
    end

  end