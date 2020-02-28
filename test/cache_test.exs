defmodule CacheTest do
  use ExUnit.Case, async: true
  doctest Cache

  setup do
    {:ok, cache} = Cache.start_link([])

    {:ok, cache: cache}
  end

  test "it returns {:error, :not_found} for novel keys", %{cache: cache} do
    assert Cache.get(cache, :key) == {:error, :not_found}
    assert Cache.get(cache, :other_key) == {:error, :not_found}
  end

  test "it can store nil as a legitimate value", %{cache: cache} do
    :ok = Cache.put(cache, :key, nil)
    {:ok, values} = Cache.get(cache, :key)
    assert MapSet.size(values) == 1
    assert nil in values
  end

  test "it stores distinct sets under distinct keys", %{cache: cache} do
    cache = initial_writes(cache)
    {:ok, values_under_key} = Cache.get(cache, :key)
    {:ok, values_under_other_key} = Cache.get(cache, :other_key)

    assert "value1" in values_under_key
    assert "value2" in values_under_key
    refute "other value" in values_under_key

    assert "other value" in values_under_other_key
    refute "value1" in values_under_other_key
    refute "value2" in values_under_other_key
  end

  test "it deletes values from distinct sets under distinct keys", %{cache: cache} do
    cache = initial_writes(cache)
    :ok = Cache.delete(cache, :key, "value2")

    {:ok, values_under_key} = Cache.get(cache, :key)
    assert "value1" in values_under_key
    refute "value2" in values_under_key

    :ok = Cache.delete(cache, :other_key, "other value")
    {:ok, values_under_other_key} = Cache.get(cache, :other_key)
    refute "other value" in values_under_other_key
  end

  ### PRIVATE FUNCTIONS

  defp initial_writes(cache) do
    :ok = Cache.put(cache, :key, "value1")
    :ok = Cache.put(cache, :key, "value2")
    :ok = Cache.put(cache, :other_key, "other value")
    cache
  end
end
