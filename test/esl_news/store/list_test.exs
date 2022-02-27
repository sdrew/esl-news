defmodule EslNews.Store.ListTest do
  use ExUnit.Case
  alias EslNews.Test.TestHelper

  doctest EslNews.Store.List

  setup_all do
    keys = [:topstories, :beststories]

    records =
      TestHelper.load_fixtures(:lists, keys)
      |> Enum.map(fn {key, list} ->
        {key, %{id: key, items: list, time: 54321}}
      end)
      |> Enum.into(%{})

    first_key =
      keys
      |> List.first()

    {:ok, %{first_key: first_key, keys: keys, records: records}}
  end

  setup ctx do
    # Remove existing inserted records before every test
    :mnesia.transaction(fn ->
      ctx.keys
      |> Enum.each(fn id ->
        :mnesia.delete({EslNews.Store.List, id})
      end)
    end)

    :ok
  end

  describe "#all()" do
    test "returns an empty list without an existing EslNews.Store.List" do
      assert EslNews.Store.List.all() == []
    end

    test "returns a list with a single existing EslNews.Store.List", ctx do
      subject = struct(EslNews.Store.List, ctx.records[ctx.first_key])
      EslNews.Store.List.create(subject)

      assert EslNews.Store.List.all() == [subject]
    end

    test "returns a list with a multiple existing EslNews.Store.List", ctx do
      subject_1 = struct(EslNews.Store.List, ctx.records[Enum.at(ctx.keys, 0)])
      EslNews.Store.List.create(subject_1)

      subject_2 = struct(EslNews.Store.List, ctx.records[Enum.at(ctx.keys, 1)])
      EslNews.Store.List.create(subject_2)

      assert EslNews.Store.List.all() == [subject_1, subject_2]
    end
  end

  describe "#create()" do
    test "persists an EslNews.Store.List struct", ctx do
      subject = struct(EslNews.Store.List, ctx.records[ctx.first_key])

      assert EslNews.Store.List.create(subject) == :ok
    end

    test "does not persist a duplicate EslNews.Store.List struct", ctx do
      subject = struct(EslNews.Store.List, ctx.records[ctx.first_key])

      assert EslNews.Store.List.create(subject) == :ok
      assert EslNews.Store.List.create(subject) == :record_exists
    end
  end

  describe "#decode()" do
    test "converts a :mnesia record tuple into an EslNews.Store.List struct", ctx do
      record = ctx.records[ctx.first_key]
      subject = struct(EslNews.Store.List, record)

      tuple = {EslNews.Store.List, record.id, record.items, record.time}

      assert EslNews.Store.List.decode(tuple) == subject
    end
  end

  describe "#delete()" do
    test "removes an existing :mnesia record", ctx do
      record = ctx.records[ctx.first_key]
      subject = struct(EslNews.Store.List, record)

      assert EslNews.Store.List.create(subject) == :ok
      assert EslNews.Store.List.all() == [subject]
      assert EslNews.Store.List.delete(subject) == :ok
      assert EslNews.Store.List.all() == []
    end

    test "no error when record does not exist", ctx do
      record = ctx.records[ctx.first_key]
      subject = struct(EslNews.Store.List, record)

      assert EslNews.Store.List.delete(subject) == :ok
    end
  end

  describe "#encode()" do
    test "converts an EslNews.Store.List struct into a :mnesia record tuple", ctx do
      subject = struct(EslNews.Store.List, ctx.records[ctx.first_key])

      assert EslNews.Store.List.encode(subject) ==
               {EslNews.Store.List, subject.id, subject.items, subject.time}
    end
  end

  describe "#find()" do
    test "returns existing EslNews.Store.List", ctx do
      record = ctx.records[ctx.first_key]
      subject = struct(EslNews.Store.List, record)

      assert EslNews.Store.List.create(subject) == :ok
      assert EslNews.Store.List.find(subject.id) == {:ok, subject}
    end

    test "returns :not_found for an unknown EslNews.Store.List" do
      assert EslNews.Store.List.find(:unknownstories) == {:not_found, nil}
    end
  end

  describe "#schema_attrs()" do
    test "returns attributes list with :id as the first element" do
      attrs = EslNews.Store.List.schema_attrs()
      keys = struct(EslNews.Store.List, []) |> Map.keys() |> List.delete(:__struct__)

      assert List.first(attrs) == :id
      assert Enum.count(attrs) == Enum.count(keys)
    end
  end

  describe "#schema_indices()" do
    test "returns index positions list" do
      indices = EslNews.Store.List.schema_indices([:items, :time])

      assert indices == [1, 2]
    end

    test "will not include :id index in list" do
      indices = EslNews.Store.List.schema_indices([:items, :id])

      assert indices == [1]
    end

    test "will handle empty attrs list" do
      indices = EslNews.Store.List.schema_indices([])

      assert indices == []
    end
  end
end
