defmodule Register do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: :register)
  end

  def init(arg) do
    {:ok, socket} = :gen_tcp.listen(4040, [:binary, packet: :line, active: false, reuseaddr: true])
    IO.puts("Ready to serve registration")
    Task.start_link(fn -> loop_acceptor(socket) end)

    {:ok, []}
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    {_, _} = :gen_tcp.shutdown(socket, :read_write)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket |> read_data("")
    # serve(socket)
  end

  # defp read_data(socket, data) do
  #   case :gen_tcp.recv(socket, 0) do
  #     {:ok, chunk} ->
  #       read_data(socket, [chunk | data])
  #     {:error, :closed} ->
  #       reconstruct_data(Enum.reverse(data)) |> map_action()
  #     {:error, cause} ->
  #       :ok
  #       # IO.puts(cause)
  #   end
  # end

    defp read_data(socket, message) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, data} ->
          if (String.contains?(data, "/q")) do
            String.replace(data, "/q", "") |> reconstruct_data() |> map_action()
          else
            read_data(socket, message <> data)
          end
          {:error, _} ->
            :ok
        end
    end


  defp reconstruct_data(message) do
    # x =
    x = try do
      Poison.decode!(message)
    rescue
      _ ->
        for c <- message, into: "", do: c
      end

    x
  end

  def map_action(message) do
    IO.inspect(message)
    case Map.get(message, "action") do
      "register" ->
        if Map.get(message, "type") == "producer" do
          register_publisher(message)
        else
          register_subscriber(message)
        end
      "subscribe" ->
        add_subscription(message)
      "unsubscribe" ->
        delete_subscription(message)
       other ->
        GenServer.cast(:dead_letter, message)
    end
  end

  def register_publisher(message) do
    try do
      DynamicSupervisor.start_child(PublisherSupervisor, Supervisor.child_spec({PublisherListener, String.to_atom(Map.get(message, "name"))}, id: String.to_atom(Map.get(message, "name"))))
      GenServer.cast(:mess_router, {:add_producer, message})
    rescue
     _ ->
      IO.puts("Already registered")
     end
  end

  def register_subscriber(message) do
    case Map.get(message, "protocol") do
      "tcp" ->
        try do
        DynamicSupervisor.start_child(SubscriberSupervisor, Supervisor.child_spec({TcpSubscriberClient, String.to_atom(Map.get(message, "name"))}, id: String.to_atom(Map.get(message, "name"))))
        GenServer.cast(:mess_router, {:add_subscriber, message})
        rescue
          _ ->
            IO.puts("Already registered")
           end
        "mqtt"->
          try do
            DynamicSupervisor.start_child(SubscriberSupervisor, Supervisor.child_spec({MqttSubscriberClient, String.to_atom(Map.get(message, "name"))}, id: String.to_atom(Map.get(message, "name"))))
            GenServer.cast(:mess_router, {:add_subscriber, message})
          rescue
            _ ->
              IO.puts("Already registered")
          end
        other ->
        GenServer.cast(:dead_letter, message)
      end
  end

  def add_subscription(message) do
    GenServer.cast(:mess_router, {:add_subscription, message})
  end

  def delete_subscription(message) do
    GenServer.cast(:mess_router, {:delete_subscription, message})
  end

  def handle_info(msg, _state) do
      IO.puts(msg)
  end

end
