defmodule IPFS do
  @moduledoc """
  Provides abstration allowing to access IPFS nodes with low effort.
  """

  @http_client HTTPoison

  @typedoc "Represents an endpoint path to hit."
  @type path :: String.t()
  @typedoc "Identifies content on the IPFS network using a multihash string."
  @type cid :: String.t()
  @typedoc "Represents an absolute filename existing on disk."
  @type filename :: String.t()
  @typedoc "Models the result of most of the functions accessible in this module."
  @type result :: {:ok, %{}} | {:error, any}

  @typedoc "Represents the endpoint to hit. Required as the first argument of most functions."
  @type t :: %__MODULE__{scheme: String.t(), host: String.t(), port: pos_integer, base: path}
  defstruct scheme: "http", host: "localhost", port: 9095, base: "api/v0"

  @doc "Retrieves version information about the running IPFS node."
  @spec version(t) :: result
  def version(conn), do: get(conn, "version")

  @doc "Lists all keys stored in the local node."
  @spec key_list(t) :: result
  def key_list(conn), do: get(conn, "key/list")

  @doc "Adds content identified by its filename on disk to the IPFS network."
  @spec add(t, filename) :: result
  def add(conn, filename), do: post_file(conn, "add", filename)

  @doc "List all pins registered on this node."
  @spec pin_ls(t) :: result
  def pin_ls(conn), do: get(conn, "pin/ls")

  @doc "Instructs the node to pin a given CID."
  @spec pin_add(t, cid) :: result
  def pin_add(conn, cid), do: get(conn, "pin/add/#{cid}")

  @doc "Instructs the node to let go of a given CID."
  @spec pin_rm(t, cid) :: result
  def pin_rm(conn, cid), do: get(conn, "pin/rm/#{cid}")

  @doc "High level function allowing to perform GET requests to the node."
  @spec get(t, path) :: result
  def get(conn, path) do
    request(conn, path, &@http_client.get(&1))
  end

  @doc "High level function allowing to send file contents to the node."
  @spec post_file(t, path, filename) :: result
  def post_file(conn, path, filename) do
    request(conn, path, &@http_client.post(&1, multipart(filename)))
  end

  # Private stuff.

  @typep requester :: (String.t() -> {:ok, any} | {:error, any})

  @spec request(t, path, requester) :: result
  defp request(conn, path, requester) do
    conn
    |> (&"#{&1.scheme}://#{&1.host}:#{&1.port}/#{&1.base}/#{path}").()
    |> requester.()
    |> to_result
  end

  @spec to_result({:ok, any} | {:error, any}) :: result
  defp to_result({:ok, %HTTPoison.Response{status_code: 200, body: b}}) do
    Poison.decode(b)
  end

  defp to_result({:ok, %HTTPoison.Response{status_code: c, body: b}}) do
    {:error, "Error status code: #{c}, #{b}"}
  end

  defp to_result({:error, %HTTPoison.Error{reason: err}}) do
    {:error, err}
  end

  @spec multipart(filename) ::
          {:multipart,
           [{:file, filename, {String.t(), [name: String.t(), filename: filename]}, []}]}
  defp multipart(filename) do
    {:multipart,
     [{:file, filename, {"form-data", [name: Path.basename(filename), filename: filename]}, []}]}
  end
end
