defmodule Cache do
  @moduledoc """
  Documentation for `Cache`.

  Taken from https://keathley.io/blog/reusable-libraries.html

  Modified to store MapSets, rather than single values,
  and to use an Agent, rather than a GenServer
  """

  use Agent

  @name __MODULE__

  @typep change_response :: :ok | {:error, term()}
  @typep get_response :: {:ok, term()} | {:error, :not_found}
  @typep start_link_response :: {:ok, pid()} | {:error, term()}

  ### BOILERPLATE

  @spec start_link() :: start_link_response()
  def start_link do
    Agent.start_link(fn -> Map.new() end, name: @name)
  end

  ### API

  @doc """
    iex> Cache.put(:a_key, :a_value)
    iex> {:ok, [val]} = Cache.get(:a_key)
    iex> val
    :a_value
  """
  @spec get(term()) :: get_response()
  def get(key, opts \\ []) do
    Agent.get(@name, fn state -> read(state, key, opts) end)
  end

  @spec put(term(), term()) :: change_response()
  def put(key, value) do
    update(key, value, &MapSet.put/2)
  end

  @doc """
    iex> Cache.put(:a_key, :a_value)
    iex> Cache.put(:a_key, :another_value)
    iex> {:ok, vals} = Cache.get(:a_key)
    iex> :a_value in vals and :another_value in vals
    true

    iex> Cache.put(:a_key, :a_value)
    iex> Cache.put(:a_key, :another_value)
    iex> Cache.delete(:a_key, :a_value)
    iex> {:ok, [val]} = Cache.get(:a_key)
    iex> val
    :another_value
  """
  @spec delete(term(), term()) :: change_response()
  def delete(key, value) do
    update(key, value, &MapSet.delete/2)
  end

  ### PRIVATE FUNCTIONS

  defp read(state, key, opts) when is_map(state) and is_list(opts) do
    if Map.has_key?(state, key) do
      values = state |> Map.get(key) |> MapSet.to_list()
      {:ok, values |> sort(opts) |> truncate(opts)}
    else
      {:error, :not_found}
    end
  end

  defp sort(values, opts) when is_list(values) and is_list(opts) do
    if Keyword.get(opts, :sort?, false) do
      Enum.sort(values)
    else
      values
    end
  end

  defp truncate(values, opts) when is_list(values) and is_list(opts) do
    if limit = Keyword.get(opts, :limit) do
      Enum.take(values, limit)
    else
      values
    end
  end

  defp update(key, value, operation) when is_function(operation, 2) do
    Agent.update(
      @name,
      fn state ->
        old_set = Map.get(state, key, MapSet.new())
        new_set = operation.(old_set, value)
        Map.put(state, key, new_set)
      end
    )
  end
end
