defmodule MessageCacher do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: :mess_cacher)
  end

  def init(arg) do
    {:ok, %{producers: [], consumers: []}}
  end

  def handle_cast({:add_consumer, name}, state) do
    {}
  end

  def handle_cast({:add_producer, name}, state) do

  end
end
