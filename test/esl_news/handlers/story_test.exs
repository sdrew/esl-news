defmodule EslNews.Handlers.StoryTest do
  use ExUnit.Case
  alias EslNews.Test.TestHelper

  doctest EslNews.Handlers.Story

  @base_url "http://localhost:8081/api/"

  setup_all do
    keys = [14_894_769, 18_264_710]
    records = TestHelper.load_fixtures(:items, keys)

    first_key =
      keys
      |> List.first()

    {:ok, %{first_key: first_key, keys: keys, records: records}}
  end

  setup ctx do
    # Remove existing inserted records before every test
    :mnesia.transaction(fn ->
      ctx.records
      |> Enum.each(fn {_key, record} ->
        :mnesia.delete({EslNews.Store.Story, record.id})
      end)
    end)

    :ok
  end

  describe "HTTP endpoint" do
    test "responds with 404 for unknown story ID" do
      {:ok, resp} = Tesla.get("#{@base_url}stories/1234")

      assert resp.status == 404
    end

    test "responds with 200 for existing story ID", ctx do
      subject = struct(EslNews.Store.Story, ctx.records[ctx.first_key])

      assert EslNews.Store.Story.create(subject) == :ok

      {:ok, resp} = Tesla.get("#{@base_url}stories/#{subject.id}")

      assert resp.status == 200
      assert resp.body == Jason.encode!(subject)

      assert resp.headers |> List.keyfind("content-type", 0) ==
               {"content-type", "application/json"}
    end
  end

  # ============
  # EslNews.Handler callbacks
  # ============

  describe "#response()" do
    test "provides JSON response for existing story ID", ctx do
      subject = struct(EslNews.Store.Story, ctx.records[ctx.first_key])

      req = %{
        method: "GET",
        path: "/api/stories/#{subject.id}",
        bindings: %{id: "#{subject.id}"},
        qs: ""
      }

      state = [id: subject.id, story: subject]
      resp = EslNews.Handlers.Story.response(req, state)

      assert elem(resp, 0) == Jason.encode!(subject)
      assert elem(resp, 1) == req
      assert elem(resp, 2) == state
    end
  end

  # ============
  # :cowboy_rest callbacks
  # ============

  describe "#init()" do
    test "upgrades :cowboy_handler to :cowboy_rest" do
      resp = EslNews.Handlers.Story.init(%{}, [])

      assert elem(resp, 0) == :cowboy_rest
      assert elem(resp, 1) == %{}
      assert elem(resp, 2) == []
    end
  end

  describe "#allowed_methods()" do
    test "only permits GET, HEAD and OPTIONS" do
      resp = EslNews.Handlers.Story.allowed_methods(%{}, [])

      assert elem(resp, 0) == ["GET", "HEAD", "OPTIONS"]
      assert elem(resp, 1) == %{}
      assert elem(resp, 2) == []
    end
  end

  describe "#content_types_provided()" do
    test "only allows for application/json" do
      resp = EslNews.Handlers.Story.content_types_provided(%{}, [])

      assert elem(resp, 0) == [{"application/json", :response}]
      assert elem(resp, 1) == %{}
      assert elem(resp, 2) == []
    end
  end

  describe "#resource_exists()" do
    test "stops middleware pipeline without existing EslNews.Store.Story" do
      req = %{method: "GET", path: "/api/stories/1234", bindings: %{id: "1234"}, qs: ""}

      resp = EslNews.Handlers.Story.resource_exists(req, [])

      assert elem(resp, 0) == false
      assert elem(resp, 1) == req
      assert elem(resp, 2) == [id: 1234]
    end

    test "permits middleware pipeline to continue with an existing EslNews.Store.Story", ctx do
      subject = struct(EslNews.Store.Story, ctx.records[ctx.first_key])

      req = %{
        method: "GET",
        path: "/api/stories/#{subject.id}",
        bindings: %{id: "#{subject.id}"},
        qs: ""
      }

      assert EslNews.Store.Story.create(subject) == :ok

      resp = EslNews.Handlers.Story.resource_exists(req, [])

      assert elem(resp, 0) == true
      assert elem(resp, 1) == req
      assert elem(resp, 2) == [id: subject.id, story: subject]

      assert EslNews.Store.Story.delete(subject) == :ok
    end
  end
end
