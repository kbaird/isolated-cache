defmodule Cache do
  @moduledoc """
  Documentation for `Cache`.

  Taken from https://keathley.io/blog/reusable-libraries.html

  Modified to store MapSets, rather than single values
  """

  use GenServer

  @typep cache :: pid()
  @typep key :: term()
  @typep get_response :: {:ok, term()} | {:error, :not_found}
  @typep change_response :: :ok | {:error, term()}
  @typep start_link_response :: {:ok, pid()} | {:error, term()} | :ignore

  ### BOILERPLATE

  @spec child_spec(map()) :: map()
  def child_spec(opts) do
    %{
      id: opts[:name] || __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec init(map()) :: {:ok, map()}
  def init(opts) do
    {:ok, %{kvs: %{}, opts: opts}}
  end

  @spec start_link() :: start_link_response()
  def start_link, do: start_link([])

  @spec start_link(Keyword.t()) :: start_link_response()
  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  ### API

  @spec get(cache(), key()) :: get_response()
  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  @spec put(cache(), key(), term()) :: change_response()
  def put(server, key, value) do
    GenServer.cast(server, {:put, key, value})
  end

  @spec delete(cache(), key(), term()) :: change_response()
  def delete(server, key, val) do
    GenServer.cast(server, {:delete, key, val})
  end

  ### HANDLERS

  def handle_call({:get, key}, _from, %{kvs: kvs} = data) when is_map(kvs) do
    {:reply, read(kvs, key), data}
  end

  def handle_cast({:put, key, val}, %{kvs: kvs} = data) when is_map(kvs) do
    new_set = kvs |> state(key) |> MapSet.put(val)
    {:noreply, put_in(data, [:kvs, key], new_set)}
  end

  def handle_cast({:delete, key, val}, %{kvs: kvs} = data) when is_map(kvs) do
    new_set = kvs |> state(key) |> MapSet.delete(val)
    {:noreply, put_in(data, [:kvs, key], new_set)}
  end

  ### PRIVATE FUNCTIONS

  defp read(kvs, key) when is_map(kvs) do
    if Map.has_key?(kvs, key) do
      {:ok, kvs[key]}
    else
      {:error, :not_found}
    end
  end

  defp state(kvs, key) when is_map(kvs) do
    kvs[key] || MapSet.new()
  end
end
