defmodule CacheTest do
  use ExUnit.Case

  # https://hexdocs.pm/propcheck/readme.html
  use PropCheck

  doctest Cache

  setup :initial_cache

  describe "with an unknown key" do
    test "returns {:error, :not_found}" do
      assert {:error, :not_found} = Cache.get(:key)
      assert {:error, :not_found} = Cache.get(:other_key)
    end
  end

  describe "with a known/legitimate key" do
    test "can store nil as a legitimate value" do
      :ok = Cache.put(:key, nil)
      {:ok, values} = Cache.get(:key)
      assert nil in values
    end
  end

  describe "with multiple distinct keys" do
    setup :seed_under_distinct_keys

    test "stores only the correct values under the first key" do
      {:ok, values_under_key} = Cache.get(:key)
      assert "value1" in values_under_key
      assert "value2" in values_under_key
      refute "other value" in values_under_key
    end

    test "stores only the correct values under the second key" do
      {:ok, values_under_other_key} = Cache.get(:other_key)
      assert "other value" in values_under_other_key
      refute "value1" in values_under_other_key
      refute "value2" in values_under_other_key
    end

    test "deletes values from the first key" do
      :ok = Cache.delete(:key, "value2")
      {:ok, values_under_key} = Cache.get(:key)
      assert "value1" in values_under_key
      refute "value2" in values_under_key
    end

    test "deletes values from the second key" do
      :ok = Cache.delete(:other_key, "other value")
      {:ok, values_under_other_key} = Cache.get(:other_key)
      refute "other value" in values_under_other_key
    end
  end

  describe "get/2" do
    setup :seed_under_distinct_keys

    test "respects the limit option" do
      {:ok, values_under_key} = Cache.get(:key)
      assert length(values_under_key) > 1
      {:ok, one_value} = Cache.get(:key, limit: 1)
      assert length(one_value) == 1
    end

    property "always returns a sorted list with sort?: true" do
      quickcheck(
        forall values <- non_empty(list(integer())) do
          Cache.clear()
          Enum.each(values, fn v -> Cache.put(:key, v) end)
          {:ok, raw_values} = Cache.get(:key)
          {:ok, sorted_values} = Cache.get(:key, sort?: true)
          assert sorted_values == Enum.sort(raw_values)
        end
      )
    end
  end

  describe "has_key?/1" do
    test "returns false for an unknown key" do
      refute Cache.has_key?(:key)
    end

    test "returns true for a known key" do
      :ok = Cache.put(:key, :a_value)
      assert Cache.has_key?(:key)
    end

    test "still returns true after all values are removed" do
      :ok = Cache.put(:key, :a_value)
      :ok = Cache.delete(:key, :a_value)
      assert Cache.has_key?(:key)
    end

    test "returns false after cache is cleared" do
      :ok = Cache.put(:key, :a_value)
      Cache.clear()
      refute Cache.has_key?(:key)
    end
  end

  describe "keys/0" do
    test "returns an empty list for an empty cache" do
      {:ok, []} = Cache.keys()
    end

    test "returns all keys" do
      :ok = Cache.put(:key, :a_value)
      :ok = Cache.put(:other_key, :other_value)
      {:ok, keys} = Cache.keys()
      assert :key in keys
      assert :other_key in keys
    end

    test "returns no keys after cache is cleared" do
      :ok = Cache.put(:key, :a_value)
      Cache.clear()
      {:ok, []} = Cache.keys()
    end
  end

  ### PRIVATE FUNCTIONS

  defp initial_cache(_) do
    if pid = Process.whereis(Cache) do
      :ok = Agent.stop(pid)
    end

    {:ok, cache} = Cache.start_link()
    {:ok, cache: cache}
  end

  defp seed_under_distinct_keys(_) do
    :ok = Cache.put(:key, "value2")
    :ok = Cache.put(:key, "value1")
    :ok = Cache.put(:other_key, "other value")
    :ok
  end
end
