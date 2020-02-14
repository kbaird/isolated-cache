defmodule CacheTest do
  use ExUnit.Case, async: true
  doctest Cache

  setup do
    {:ok, cache} = Cache.start_link([])

    {:ok, cache: cache}
  end

  test "it returns nil for novel keys", %{cache: cache} do
    assert Cache.get(cache, :key) == nil
    assert Cache.get(cache, :other_key) == nil
  end

  test "it stores distinct sets under distinct keys", %{cache: cache} do
    cache = initial_writes(cache)
    values_under_key = Cache.get(cache, :key)
    values_under_other_key = Cache.get(cache, :other_key)

    assert "value1" in values_under_key
    assert "value2" in values_under_key
    refute "other value" in values_under_key

    assert "other value" in values_under_other_key
    refute "value1" in values_under_other_key
    refute "value2" in values_under_other_key
  end

  test "it removes values from distinct sets under distinct keys", %{cache: cache} do
    cache = initial_writes(cache)
    :ok = Cache.remove(cache, :key, "value2")

    values_under_key = Cache.get(cache, :key)
    assert "value1" in values_under_key
    refute "value2" in values_under_key

    :ok = Cache.remove(cache, :other_key, "other value")
    refute "other value" in Cache.get(cache, :other_key)
  end

  ### PRIVATE FUNCTIONS

  defp initial_writes(cache) do
    :ok = Cache.put(cache, :key, "value1")
    :ok = Cache.put(cache, :key, "value2")
    :ok = Cache.put(cache, :other_key, "other value")
    cache
  end
end
