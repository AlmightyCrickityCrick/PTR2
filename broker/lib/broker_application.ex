defmodule BrokerApplication do
  use Application

  def start(_type, _args) do
    {_resp, pid}= PubSub.start_link([])
  end
end