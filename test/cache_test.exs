defmodule CacheTest do
  use ExUnit.Case, async: true
  doctest Cache

  setup do
    {:ok, cache} = Cache.start_link([])

    {:ok, cache: cache}
  end

  ### TODO: break these up
  test "it stores distinct sets under distinct keys", %{cache: cache} do
    assert Cache.get(cache, :key) == nil
    :ok = Cache.put(cache, :key, "value1")
    :ok = Cache.put(cache, :key, "value2")
    assert Cache.get(cache, :other_key) == nil

    :ok = Cache.put(cache, :other_key, "other value")
    assert "other value" in Cache.get(cache, :other_key)
    values_under_key = Cache.get(cache, :key)
    assert "value1" in values_under_key
    assert "value2" in values_under_key

    :ok = Cache.remove(cache, :key, "value2")
    values_under_key = Cache.get(cache, :key)
    assert "value1" in values_under_key
    refute "value2" in values_under_key

    :ok = Cache.remove(cache, :other_key, "other value")
    refute "other value" in Cache.get(cache, :other_key)
  end
end
