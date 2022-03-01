defmodule EslNews.Websocket do
  @moduledoc """
  `EslNews.Websocket` provides a standard base implementing the `:cowboy_websocket` behaviour
  and URI param extraction for `EslNews.Handlers`
  """

  @typedoc """
  `:cowboy_websocket.call_result()` type isn't exported by `:cowboy_websocket`
  """
  @type call_result() ::
          {:cowboy_websocket.commands(), any} | {:cowboy_websocket.commands(), any, :hibernate}

  # =========
  # `:cowboy_websocket` behaviour callbacks
  # =========
  @callback init(:cowboy_req.req(), any) :: {:cowboy_websocket, :cowboy_req.req(), any}
  @callback websocket_init(any) :: call_result()
  @callback websocket_handle(:ping | :pong | {:text | :binary | :ping | :pong, binary()}, any) ::
              call_result()
  @callback websocket_info(any, any) :: call_result()
  @callback terminate(any, :cowboy_req.req(), any) :: :ok

  @optional_callbacks websocket_init: 1, terminate: 3

  @spec __using__(any) :: {atom(), list(), list()}
  defmacro __using__(_) do
    quote do
      alias EslNews.{Handler, Logger, Websocket}

      @behaviour EslNews.Websocket

      @ws_idle_timeout 30_000

      @typedoc """
      `:cowboy_websocket.call_result()` type isn't exported by `:cowboy_websocket`
      """
      @type call_result() ::
              {:cowboy_websocket.commands(), any}
              | {:cowboy_websocket.commands(), any, :hibernate}

      @doc """
      Upgrade a basic `:cowboy_handler` middleware to the `:cowboy_websocket` middleware
      """
      @impl true
      @spec init(:cowboy_req.req(), any) :: {:cowboy_websocket, :cowboy_req.req(), any}
      def init(request, state) do
        params = Handler.request_params(request, permit: [:type])
        state = state ++ [params: params]

        case :cowboy_req.parse_header("sec-websocket-protocol", request) do
          :undefined ->
            {:cowboy_websocket, request, state, %{idle_timeout: @ws_idle_timeout}}

          protocol ->
            Logger.info(protocol)
            {:cowboy_websocket, request, state, %{idle_timeout: @ws_idle_timeout}}
        end
      end

      @doc """
      Log a successful connection and dispatch the initial call to `websocket_info/2` after 10ms
      """
      @impl true
      @spec websocket_init(any) :: call_result()
      def websocket_init(state) do
        Logger.info("WS Connect")

        :erlang.start_timer(10, self(), :connected)
        {[active: true], state}
      end

      @doc """
      Receives pings/data from the connection. Ignores and continues.
      """
      @impl true
      @spec websocket_handle(:ping | :pong | {:text | :binary | :ping | :pong, binary()}, any) ::
              call_result()
      def websocket_handle(call, state) do
        Logger.ws(call, state)

        {[active: true], state}
      end

      @doc """
      Logs when a connection is terminated.
      """
      @impl true
      @spec terminate(any, :cowboy_req.req(), any) :: :ok
      def terminate(_call, _request, _state) do
        Logger.info("WS Terminate")

        :ok
      end
    end
  end
end
