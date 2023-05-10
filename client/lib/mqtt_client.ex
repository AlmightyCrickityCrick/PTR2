defmodule MQTTClient do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, "client#{args}", name: String.to_atom("client#{args}"))
  end

  def init(name) do
    register(name)
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 7000, [:binary, packet: :line, active: false])

    Task.start_link(fn -> listen(name, socket) end)


    t = :timer.send_after(10000, :subscribe)
    t = :timer.send_after(5000, :publish)
    {:ok, %{name: name, socket: socket, messages: %{}}}
  end

  def handle_info(:subscribe, state) do
    n =Map.get(state, :name)
    subscribe(n, "producer#{String.replace(n , "client", "")}")
    {:noreply, state}
  end

  def handle_info(:publish, state) do
    IO.puts("New message in mqtt")
    m = make_message(Map.get(state, :name))
    new_messages = Map.get(state, :messages) |> Map.put(Map.get(m, :id), m)
    :gen_tcp.send(Map.get(state, :socket), Poison.encode!(m)<>"/q\n" )
    t = :timer.send_after(5000, :publish)
    {:noreply, %{name: Map.get(state, :name), socket: Map.get(state, :socket), messages: new_messages}}
  end

  def make_message(name) do
    topics = ["kittens", "puppies", "tweets", "garbage"]
    content = ["Hello", "Bye", "Elixir is a dynamic, functional \nlanguage for building scalable and maintainable applications", "meaow", "woof"]
    message = if(Enum.random([0, 1]) == 0) do
     %{producer: name, topic: Enum.random(topics), content: Enum.random(content), id: Enum.random(1..999999)}
    else
      %{topic: Enum.random(topics), content: Enum.random(content), id: Enum.random(1..999999)}
    end
    message
  end

  def handle_cast({:delete, id}, state) do
    new_messages = Map.get(state, :messages) |> Map.delete(id)

    {:noreply, %{name: Map.get(state, :name), socket: Map.get(state, :socket), messages: new_messages}}

  end

  def register(name) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4000, [:binary, packet: :raw, active: false])
    IO.puts("Starting #{name}")
    Process.sleep(100)
    msg = %{type: "client", protocol: "mqtt" , action: "register", name: name}
    msg_to_send = Poison.encode!(msg)
    resp = :gen_tcp.send(socket, msg_to_send <> "/q\n")
    r = :gen_tcp.shutdown(socket, :read_write)
  end

  def listen(name, socket) do
    mess = read_message(socket, "")
    IO.puts(mess)
    if(String.contains?(mess, "introduce")) do
      IO.puts("Introducing myself")
      :gen_tcp.send(socket, Poison.encode!(%{type: "introduction", name: name}) <> "/q\n")
    end

    subscribe(name, Enum.random(["puppies", "kittens", "garbage"]))

    listening_loop(socket, name)

  end

  def subscribe(name, topic) do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4000, [:binary, packet: :raw, active: false])
    msg = %{to: topic, type: "topic"  , action: "subscribe", name: name}
    msg_to_send = Poison.encode!(msg)
    resp = :gen_tcp.send(socket, msg_to_send <> "/q\n")
    r = :gen_tcp.shutdown(socket, :read_write)
  end

  def listening_loop(socket, name) do
    m = read_message(socket, "")
    _r = inspect_message(m, socket, name)
    listening_loop(socket, name)
  end

  defp inspect_message(message, socket, name) do
    m = Poison.decode!(message)
    IO.puts("#{name} received #{inspect(m)}")
    case Map.get(m, "type") do
      "PUBREC" -> :gen_tcp.send(socket, Poison.encode!(%{type: "PUBREL", id: Map.get(m, "id")}) <> "/q\n")
      "PUBCOMP" -> GenServer.cast(String.to_atom(name), {:delete, Map.get(m, "id")})
        other ->  resp = :gen_tcp.send(socket, Poison.encode!(%{type: "received", id: Map.get(m, "id")}) <> "/q\n")
    end
    :ok
  end

  defp read_message(socket, message) do
    case :gen_tcp.recv(socket, 0) do
    {:ok, data} ->
      if (String.contains?(data, "/q")) do
        String.replace(data, "/q", "")
      else
        read_message(socket, message <> data)
      end
      {:error, _} ->
        ""
    end
  end
end
