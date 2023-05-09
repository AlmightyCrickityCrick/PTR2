defmodule DeadLetter do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: :dead_letter)
  end

  def init(arg) do
    {:ok, []}
  end


  def handle_cast(message, state) do
    IO.puts("New message in dead letter")
    new_state = List.insert_at(state, -1, message)

    {:noreply, new_state}
  end
end
