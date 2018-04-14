defmodule IPFSTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest IPFS, import: true

  setup :ipfs_conn

  test "can fetch the node's version", %{conn: conn} do
    {:ok, versions} = IPFS.version(conn)
    assert is_map(versions)
  end

  test "can read dht keys", %{conn: conn} do
    {:ok, keys} = IPFS.key_list(conn)
    assert is_map(keys)
  end

  defp ipfs_conn(ctx) do
    host = System.get_env("IPFS_HOST") || "localhost"
    {:ok, Map.put(ctx, :conn, %IPFS{scheme: "http", host: host, port: port(host)})}
  end

  defp port("ipfs"), do: 5001
  defp port("ipfs-cluster"), do: 9095
  defp port(_), do: 9095
end
