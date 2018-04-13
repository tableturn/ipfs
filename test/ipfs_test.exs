defmodule IPFSTest do
  @moduledoc false
  use Linky.DataCase, async: true
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
    conn = %IPFS{
      scheme: "http",
      host: System.get_env("IPFS_HOST") || "localhost",
      port: System.get_env("IPFS_PORT") || "9095"
    }

    {:ok, Map.put(ctx, :conn, conn)}
  end
end
