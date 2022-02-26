defmodule EslNews.Handler do
  @moduledoc """
  `EslNews.Handler` provides a standard base implementing the `:cowboy_rest` behaviour
  and URI param extraction for `EslNews.Handlers`
  """

  @typedoc """
  `:cowboy_rest.switch_handler()` type isn't exported by `:cowboy_rest`
  """
  @type switch_handler() :: {:switch_handler, module()} | {:switch_handler, module(), any()}

  @doc """
  `:cowboy_rest` behaviour callbacks
  """
  @callback init(:cowboy_req.req(), any) :: {:cowboy_rest, :cowboy_req.req(), any}
  @callback allowed_methods(:cowboy_req.req(), any) ::
              {[binary(), ...], :cowboy_req.req(), any}
              | {:stop, :cowboy_req.req(), any}
              | {switch_handler(), :cowboy_req.req(), any}
  @callback content_types_provided(:cowboy_req.req(), any) ::
              {[{binary() | {binary(), binary(), :* | [{binary(), binary()}]}, atom()}],
               :cowboy_req.req(), any}
              | {:stop, :cowboy_req.req(), any}
              | {switch_handler(), :cowboy_req.req(), any}

  @doc """
  `EslNews.Handler` behaviour callbacks
  """
  @callback response(:cowboy_req.req(), any) :: {binary, :cowboy_req.req(), any}

  @spec __using__(any) :: {atom(), list(), list()}
  defmacro __using__(_) do
    quote do
      alias EslNews.{Handler, Logger}

      @behaviour EslNews.Handler

      @typedoc """
      `:cowboy_rest.switch_handler()` type isn't exported by `:cowboy_rest`
      """
      @type switch_handler() :: {:switch_handler, module()} | {:switch_handler, module(), any()}

      @doc """
      Upgrade a basic :cowboy_handler middleware to the :cowboy_rest middleware
      """
      @impl true
      @spec init(:cowboy_req.req(), any) :: {:cowboy_rest, :cowboy_req.req(), any}
      def init(request, options) do
        {:cowboy_rest, request, options}
      end

      @doc """
      Only permit GET, HEAD and OPTIONS request methods for these endpoints
      """
      @impl true
      @spec allowed_methods(:cowboy_req.req(), any) ::
              {[binary(), ...], :cowboy_req.req(), any}
              | {:stop, :cowboy_req.req(), any}
              | {switch_handler(), :cowboy_req.req(), any}
      def allowed_methods(request, state) do
        {["GET", "HEAD", "OPTIONS"], request, state}
      end

      @doc """
      Only permit "application/json" content-types for these endpoints
      """
      @impl true
      @spec content_types_provided(:cowboy_req.req(), any) ::
              {[{binary() | {binary(), binary(), :* | [{binary(), binary()}]}, atom()}],
               :cowboy_req.req(), any}
              | {:stop, :cowboy_req.req(), any}
              | {switch_handler(), :cowboy_req.req(), any}
      def content_types_provided(request, state) do
        {[{"application/json", :response}], request, state}
      end
    end
  end

  @doc """
  Extract request params from path bindings and URI query string.
  - For query string params, only the permitted values will be returned,
    and they will not override path binding values.

  ## Examples
    iex> EslNews.Handler.request_params(%{qs: "page=1&per=10"}, permit: [:page, :per])
    %{page: "1", per: "10"}

    iex> EslNews.Handler.request_params(%{qs: "page=1&per=10&id=4", bindings: %{id: "1234"}}, permit: [:page])
    %{id: "1234", page: "1"}

    iex> EslNews.Handler.request_params(%{qs: "page=1&per=10"}, permit: [])
    %{}
  """
  @spec request_params(:cowboy_req.req(), [{:permit, list()}]) :: map()
  def request_params(request, opts) do
    permitted_query_params(request, opts)
    |> Map.merge(:cowboy_req.bindings(request))
  end

  defp permitted_query_params(request, opts) do
    permitted =
      Keyword.get(opts, :permit, [])
      |> Enum.map(&Atom.to_string/1)

    :cowboy_req.parse_qs(request)
    |> Enum.into(%{})
    |> Map.take(permitted)
    |> Enum.map(fn {key, val} -> {String.to_existing_atom(key), val} end)
    |> Enum.into(%{})
  end
end