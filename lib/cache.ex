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

  @spec start_link(Keyword.t()) :: {:ok, pid()} | {:error, term()} | :ignore
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

  def handle_call({:get, key}, _from, %{kvs: kvs} = data) do
    {:reply, read(kvs, key), data}
  end

  def handle_cast({:put, key, val}, data) do
    state = state(data, key)
    new_set = MapSet.put(state, val)
    {:noreply, put_in(data, [:kvs, key], new_set)}
  end

  def handle_cast({:delete, key, val}, data) do
    state = state(data, key)
    new_set = MapSet.delete(state, val)
    {:noreply, put_in(data, [:kvs, key], new_set)}
  end

  ### PRIVATE FUNCTIONS

  defp read(kvs, key) do
    if Map.has_key?(kvs, key) do
      {:ok, kvs[key]}
    else
      {:error, :not_found}
    end
  end

  defp state(data, key) do
    data.kvs[key] || MapSet.new()
  end
end
