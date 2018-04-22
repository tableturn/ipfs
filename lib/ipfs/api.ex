defmodule IPFS.API do
  @moduledoc false

  import IPFS, only: [get: 2, get: 3, post_file: 4]
  import IPFS.Utils, only: [remap_fields: 2, remap_array: 2, successify_with: 1, okify: 1]

  @type t :: IPFS.t()
  @type path :: IPFS.path()
  @type cid :: IPFS.cid()
  @type filename :: IPFS.filename()
  @type result :: IPFS.result()

  @doc "Builds a likelly to work connection struct to use with the IPFS API."
  @spec conn() :: t
  def conn(), do: %IPFS{scheme: "http", host: "localhost", port: 5001, base: "api/v0"}

  # Top-level informative endpoints.

  @doc "Retrieves the cluster peer information."
  @spec id(t) :: result
  def id(conn) do
    conn
    |> get("id")
    |> remap_fields(
      addresses: "Addresses",
      agent_version: "AgentVersion",
      id: "ID",
      protocol_version: "ProtocolVersion",
      public_key: "PublicKey"
    )
    |> okify
  end

  @doc "Retrieves version information about the running IPFS node."
  @spec version(t) :: result
  def version(conn) do
    conn
    |> get("version")
    |> remap_fields(version: "Version", commit: "Commit", system: "System", golang: "Golang")
    |> okify
  end

  # Key management.

  @doc """
  Generates a new keypair given its `name` and optional `type` and `size`.

  Note that `type` could be either one of `:rsa` or `:ed25519` only.

  Returns a `result`.
  """
  @spec key_gen(t, String.t(), :rsa | :ed25519, pos_integer) :: result
  def key_gen(conn, name, type \\ :rsa, size \\ 2048) do
    conn
    |> get("key/gen", arg: name, type: type, size: size)
    |> remap_fields(id: "Id")
    |> okify
  end

  @doc "Lists all keys stored in the local node."
  @spec key_list(t) :: result
  def key_list(conn) do
    with {:ok, %{"Keys" => keys}} <- get(conn, "key/list") do
      {:ok, keys}
      |> remap_array(id: "Id", name: "Name")
      |> okify
    end
  end

  @doc """
  Renames a keypair identified by its `name`. If `force` is set to `true`, existing
  named with a matching `new_name` will be overwritten.
  """
  @spec key_rename(t, String.t(), String.t(), boolean) :: result
  def key_rename(conn, name, new_name, force \\ false) do
    conn
    |> get("key/rename", arg: name, arg: new_name, force: force)
    |> successify_with
  end

  @doc "Removes a keypair identified by its `name`."
  def key_rm(conn, name) do
    conn
    |> get("key/rm", arg: name)
    |> successify_with
  end

  # Content management.

  @doc """
  Adds content identified by its `filename` on disk to the IPFS network.

  A range of `params` can be specified, please refer to the official
  [IPFS documentation](https://ipfs.io/docs/api/#apiv0add) for more information.
  """
  @spec add(t, filename, keyword) :: result
  def add(conn, filename, params \\ []) do
    conn
    |> post_file("add", filename, params)
    |> remap_fields(name: "Name", hash: "Hash", size: "Size")
    |> okify
  end

  # Pinning.

  @doc "List all pins registered on this node."
  @spec pin_ls(t) :: result
  def pin_ls(conn) do
    with {:ok, %{"Keys" => keys}} <- get(conn, "pin/ls") do
      {:ok, keys}
    end
  end

  @doc "Instructs the node to pin a given `cid`."
  @spec pin_add(t, cid) :: result
  def pin_add(conn, cid) do
    conn
    |> get("pin/add", arg: cid)
    |> successify_with
  end

  @doc "Instructs the node to let go of a given `cid`."
  @spec pin_rm(t, cid) :: result
  def pin_rm(conn, cid) do
    conn
    |> get("pin/rm", arg: cid)
    |> successify_with
  end
end
