defmodule IPFS do
  @moduledoc """
  Provides abstration allowing to access IPFS nodes with low effort.
  """

  alias HTTPoison.{AsyncResponse, Response, Error}

  @typedoc "Represents an endpoint path to hit."
  @type path :: String.t()
  @typedoc "Identifies content on the IPFS network using a multihash string."
  @type cid :: String.t()
  @typedoc "Represents an absolute filename existing on disk."
  @type filename :: String.t()
  @typedoc "Models the result of most of the functions accessible in this module."
  @type result :: {:ok, any} | {:error, any}

  @typep poison_result :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @typedoc "Represents the endpoint to hit. Required as the first argument of most functions."
  @type t :: %__MODULE__{scheme: String.t(), host: String.t(), port: pos_integer, base: path}
  defstruct scheme: "http", host: "localhost", port: 5001, base: "api/v0"

  @doc "Retrieves version information about the running IPFS node."
  @spec version(t) :: result
  def version(conn) do
    conn
    |> get("version")
    |> remap_fields(version: "Version", commit: "Commit", system: "System", golang: "Golang")
    |> okify
  end

  # Key management.

  @doc "Generates a new keypair given its `name` and optional `type` and `size`."
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
  Adds content identified by its filename on disk to the IPFS network.

  A range of params can be specified
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

  @doc "Instructs the node to pin a given CID."
  @spec pin_add(t, cid) :: result
  def pin_add(conn, cid) do
    conn
    |> get("pin/add", arg: cid)
    |> successify_with
  end

  @doc "Instructs the node to let go of a given CID."
  @spec pin_rm(t, cid) :: result
  def pin_rm(conn, cid) do
    conn
    |> get("pin/rm", arg: cid)
    |> successify_with
  end

  # Generic request helpers.

  @doc "High level function allowing to perform GET requests to the node."
  @spec get(t, path, keyword) :: result
  def get(conn, path, params \\ []) do
    request(conn, path, &HTTPoison.get(&1, [], params: params))
  end

  @doc "High level function allowing to send file contents to the node."
  @spec post_file(t, path, filename, keyword) :: result
  def post_file(conn, path, filename, params \\ []) do
    request(conn, path, &HTTPoison.post(&1, multipart(filename), params: params))
  end

  # Private stuff.

  @spec request(t, path, (String.t() -> poison_result)) :: result
  defp request(conn, path, requester) do
    conn
    |> (&"#{&1.scheme}://#{&1.host}:#{&1.port}/#{&1.base}/#{path}").()
    |> requester.()
    |> to_result
  end

  @spec to_result(poison_result) :: result
  defp to_result({:ok, %Response{status_code: 200, body: b}}) do
    case Poison.decode(b) do
      {:ok, _} = res -> res
      {:error, :invalid, 0} -> {:ok, %{}}
      otherwise -> otherwise
    end
  end

  defp to_result({:ok, %Response{status_code: 200}}) do
    %{}
  end

  defp to_result({:ok, %Response{status_code: c, body: b}}) do
    {:error, "Error status code: #{c}, #{b}"}
  end

  defp to_result({:error, %Error{reason: err}}) do
    {:error, err}
  end

  @spec multipart(filename) ::
          {:multipart,
           [{:file, filename, {String.t(), [name: String.t(), filename: filename]}, []}]}
  defp multipart(filename) do
    {:multipart,
     [{:file, filename, {"form-data", [name: Path.basename(filename), filename: filename]}, []}]}
  end

  @spec remap_fields(result, [{atom, String.t()}]) :: %{}
  defp remap_fields(res, mapping) do
    with {:ok, data} <- res do
      mapping
      |> Enum.into(%{})
      |> Enum.reduce(%{}, fn {to, from}, acc ->
        case Map.fetch(data, from) do
          {:ok, value} -> Map.put(acc, to, value)
          _ -> acc
        end
      end)
    end
  end

  @spec remap_array(result, [{atom, String.t()}]) :: []
  defp remap_array(res, mapping) do
    with {:ok, data} when is_list(data) <- res do
      data
      |> Enum.reduce([], fn item, acc ->
        [remap_fields({:ok, item}, mapping)] ++ acc
      end)
    end
  end

  @spec okify(any) :: {:ok, any}
  defp okify(res), do: {:ok, res}

  @spec successify_with(result) :: result
  defp successify_with({:ok, _}), do: okify(:success)
  defp successify_with(err), do: err
end
