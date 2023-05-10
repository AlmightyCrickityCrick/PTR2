defmodule MessageCacher do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: :mess_cacher)
  end

  def init(arg) do
    :ets.new(:messages, [:named_table, :set, :public])
    {:ok, []}
  end

  def handle_cast({:add_message, message}, state) do
    :ets.insert(:messages, {Map.get(message, "id"), message})
    
    {:noreply, state}
  end

  def handle_cast({:delete_message, message}, state) do
    :ets.delete(:messages, Map.get(message, "id"))
    {:noreply, state}
  end
end
