defmodule IPFS.ClusterAPI do
  @moduledoc """
  The following endpoint wrappers still need to be implemented:
  - POST /peers
  - DELETE /peers/{peerID}
  - POST /pins/sync
  - POST /pins/{cid}
  - DELETE /pins/{cid}
  - POST /pins/{cid}/sync
  - POST /pins/{cid}/recover
  """

  import IPFS, only: [get: 2]
  import IPFS.Utils, only: [remap_fields: 2, remap_array: 2, okify: 1]

  @type t :: IPFS.t()
  @type path :: IPFS.path()
  @type cid :: IPFS.cid()
  @type filename :: IPFS.filename()
  @type result :: IPFS.result()

  # Top-level informative endpoints.

  @id_fields ~w(addresses cluster_peers cluster_peers_addresses commit error id ipfs peername rpc_protocol_version version)a
             |> Enum.reduce([], &Keyword.put(&2, &1, to_string(&1)))

  @doc "Retrieves the cluster peer information."
  @spec id(t) :: result
  def id(conn) do
    conn
    |> get("id")
    |> remap_fields(@id_fields)
    |> okify
  end

  @version_fields [version: "Version"]

  @doc "Retrieves version information about the running IPFS node."
  @spec version(t) :: result
  def version(conn) do
    conn
    |> get("version")
    |> remap_fields(@version_fields)
    |> okify
  end

  # Peers operations.

  @peer_fields ~w(addresses cluster_peers commit error id ipfs peername rpc_protocol_version version)a
               |> Enum.reduce([], &Keyword.put(&2, &1, to_string(&1)))

  @spec peers(t) :: result
  def peers(conn) do
    conn
    |> get("peers")
    |> remap_array(@peer_fields)
    |> okify
  end

  # Allocations operations.

  @allocation_fields ~w(allocations cid name recursive replication_factor_max replication_factor_min)a
                     |> Enum.reduce([], &Keyword.put(&2, &1, to_string(&1)))

  @spec allocation_ls(t) :: result
  def allocation_ls(conn) do
    conn
    |> get("allocations")
    |> remap_array(@allocation_fields)
    |> okify
  end

  @spec allocation_show(t, cid) :: result
  def allocation_show(conn, cid) do
    conn
    |> get("allocations/#{cid}")
    |> remap_fields(@allocation_fields)
    |> okify
  end

  # Pin operations.

  @pin_fields ~w(cid peer_map)a
              |> Enum.reduce([], &Keyword.put(&2, &1, to_string(&1)))

  @spec pin_ls(t) :: result
  def pin_ls(conn) do
    conn
    |> get("pins")
    |> remap_array(@pin_fields)
    |> okify
  end

  @spec pin_show(t, cid) :: result
  def pin_show(conn, cid) do
    conn
    |> get("pins/#{cid}")
    |> remap_fields(@pin_fields)
    |> okify
  end
end
