defmodule IPFSTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest IPFS, import: true

  @cassette_opts [match_requests_on: [:query, :request_body]]

  setup :conn

  test "can handle errors", %{conn: conn} do
    use_cassette "errors", @cassette_opts do
      conn
      |> IPFS.get("error_please")
      |> assert_equals({:error, {:invalid, "J", 1}})
    end
  end

  test "can perform get operations", %{conn: conn} do
    use_cassette "get", @cassette_opts do
      conn
      |> IPFS.get("FourOhFour")
      |> assert_equals({:error, "Error status code: 404, 404 page not found"})

      conn
      |> IPFS.get("pin/verify")
      |> deokify
      |> assert_equals(%{})
    end
  end

  defp conn(ctx) do
    ret = %IPFS{scheme: "http", host: "localhost", port: 5001, base: "api/v0"}
    {:ok, Map.put(ctx, :conn, ret)}
  end

  defp deokify({:ok, res}), do: res
  defp assert_equals(right, left), do: assert(left == right)
end
