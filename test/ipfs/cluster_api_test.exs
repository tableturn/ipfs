defmodule IPFS.ClusterAPITest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias IPFS.ClusterAPI
  doctest ClusterAPI, import: true

  @cassette_opts [match_requests_on: [:query, :request_body]]

  @cid "QmQChpnJJ5am4HRiW7b1KZtBEBeWy3azovVMCL3xsFVUL3"
  @commit "ed55daf2c6401ce656fdc470b3a9e06f4d145c63"
  @id "QmeybQebcM9LwyyHcg7RM3ZbAgQmXKyQEGRCmHJRxycdUT"
  @version "0.3.5"
  @peername "7603af054573"
  @rpc_protocol_version "/ipfscluster/0.3.5/rpc"

  setup :conn

  test "#conn builds defaults", %{conn: %{scheme: scheme, host: host, port: port, base: base}} do
    assert "http" == scheme
    assert "localhost" == host
    assert 9094 == port
    assert nil == base
  end

  test "#id", %{conn: conn} do
    use_cassette "cluster_api/id", @cassette_opts do
      %{
        version: @version,
        addresses: addresses,
        cluster_peers: cluster_peers,
        cluster_peers_addresses: cluster_peers_addresses,
        commit: @commit,
        error: "",
        id: @id,
        ipfs: ipfs,
        peername: @peername,
        rpc_protocol_version: @rpc_protocol_version
      } =
        conn
        |> ClusterAPI.id()
        |> deokify()

      assert 2 == length(addresses)
      assert 2 == length(cluster_peers)
      assert 2 == length(cluster_peers_addresses)
      assert is_map(ipfs)
    end
  end

  test "#version", %{conn: conn} do
    use_cassette "cluster_api/version", @cassette_opts do
      conn
      |> ClusterAPI.version()
      |> deokify()
      |> assert_equals(%{version: @version})
    end
  end

  test "can perform peer related operations", %{conn: conn} do
    use_cassette "cluster_api/peers" do
      peers =
        conn
        |> ClusterAPI.peers()
        |> deokify

      assert 2 == length(peers)

      %{
        version: @version,
        addresses: addresses,
        cluster_peers: cluster_peers,
        commit: @commit,
        error: "",
        id: @id,
        ipfs: ipfs,
        peername: @peername,
        rpc_protocol_version: @rpc_protocol_version
      } = hd(peers)

      assert 2 == length(addresses)
      assert 2 == length(cluster_peers)
      assert is_map(ipfs)
    end
  end

  @allocation %{
    allocations: [
      "QmeybQebcM9LwyyHcg7RM3ZbAgQmXKyQEGRCmHJRxycdUT",
      "Qmc6H2UwRty245dRnSNJs2CANZHmZU92kVsLMhwenjB7c5"
    ],
    cid: @cid,
    name: "",
    recursive: false,
    replication_factor_max: 3,
    replication_factor_min: 1
  }

  test "can perform allocation related operations", %{conn: conn} do
    use_cassette "cluster_api/allocating" do
      conn
      |> ClusterAPI.allocation_ls()
      |> deokify
      |> assert_equals([@allocation])

      conn
      |> ClusterAPI.allocation_show(@cid)
      |> deokify
      |> assert_equals(@allocation)
    end
  end

  @pin %{
    cid: @cid,
    peer_map: %{
      "Qmc6H2UwRty245dRnSNJs2CANZHmZU92kVsLMhwenjB7c5" => %{
        "cid" => @cid,
        "error" =>
          "Post http://172.240.0.21:5001/api/v0/pin/ls?arg=#{@cid}&type=recursive: dial tcp 172.240.0.21:5001: getsockopt: connection refused",
        "peer" => "Qmc6H2UwRty245dRnSNJs2CANZHmZU92kVsLMhwenjB7c5",
        "status" => "pin_error",
        "timestamp" => "2018-04-21T19:11:45Z"
      },
      "QmeybQebcM9LwyyHcg7RM3ZbAgQmXKyQEGRCmHJRxycdUT" => %{
        "cid" => @cid,
        "error" =>
          "Post http://172.240.0.11:5001/api/v0/pin/ls?arg=#{@cid}&type=recursive: dial tcp 172.240.0.11:5001: getsockopt: connection refused",
        "peer" => "QmeybQebcM9LwyyHcg7RM3ZbAgQmXKyQEGRCmHJRxycdUT",
        "status" => "pin_error",
        "timestamp" => "2018-04-21T19:11:45Z"
      }
    }
  }

  test "can perform pin related operations", %{conn: conn} do
    use_cassette "cluster_api/pinning" do
      conn
      |> ClusterAPI.pin_ls()
      |> deokify
      |> assert_equals([@pin])

      conn
      |> ClusterAPI.pin_show(@cid)
      |> deokify
      |> assert_equals(@pin)
    end
  end

  defp conn(ctx), do: {:ok, Map.put(ctx, :conn, IPFS.ClusterAPI.conn())}

  defp deokify({:ok, res}), do: res
  defp assert_equals(right, left), do: assert(left == right)
end
